#import "PREDPrivate.h"
#import "PREDChannelPrivate.h"
#import "PREDHelper.h"
#import "PREDTelemetryContext.h"
#import "PREDTelemetryData.h"
#import "PREDPrivate.h"
#import "PREDEnvelope.h"
#import "PREDData.h"
#import "PREDDevice.h"
#import "PREDPersistencePrivate.h"

static char *const PREDDataItemsOperationsQueue = "net.hockeyapp.senderQueue";
char *PREDSafeJsonEventsString;

NSString *const PREDChannelBlockedNotification = @"PREDChannelBlockedNotification";

static NSInteger const PREDDefaultMaxBatchSize  = 50;
static NSInteger const PREDDefaultBatchInterval = 15;
static NSInteger const PREDSchemaVersion = 2;

static NSInteger const PREDDebugMaxBatchSize = 5;
static NSInteger const PREDDebugBatchInterval = 3;

NS_ASSUME_NONNULL_BEGIN

@implementation PREDChannel

@synthesize persistence = _persistence;
@synthesize channelBlocked = _channelBlocked;

#pragma mark - Initialisation

- (instancetype)init {
    if (self = [super init]) {
        pres_resetSafeJsonStream(&PREDSafeJsonEventsString);
        _dataItemCount = 0;
        if (PREDHelper.isDebuggerAttached) {
            _maxBatchSize = PREDDebugMaxBatchSize;
            _batchInterval = PREDDebugBatchInterval;
        } else {
            _maxBatchSize = PREDDefaultMaxBatchSize;
            _batchInterval = PREDDefaultBatchInterval;
        }
        dispatch_queue_t serialQueue = dispatch_queue_create(PREDDataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
        _dataItemsOperations = serialQueue;
    }
    return self;
}

- (instancetype)initWithTelemetryContext:(PREDTelemetryContext *)telemetryContext persistence:(PREDPersistence *)persistence {
    if (self = [self init]) {
        _telemetryContext = telemetryContext;
        _persistence = persistence;
    }
    return self;
}

#pragma mark - Queue management

- (BOOL)isQueueBusy {
    if (!self.channelBlocked) {
        BOOL persistenceBusy = ![self.persistence isFreeSpaceAvailable];
        if (persistenceBusy) {
            self.channelBlocked = YES;
            [self sendBlockingChannelNotification];
        }
    }
    return self.channelBlocked;
}

- (void)persistDataItemQueue {
    [self invalidateTimer];
    if (!PREDSafeJsonEventsString || strlen(PREDSafeJsonEventsString) == 0) {
        return;
    }
    
    NSData *bundle = [NSData dataWithBytes:PREDSafeJsonEventsString length:strlen(PREDSafeJsonEventsString)];
    [self.persistence persistBundle:bundle];
    
    // Reset both, the async-signal-safe and item counter.
    [self resetQueue];
}

- (void)resetQueue {
    pres_resetSafeJsonStream(&PREDSafeJsonEventsString);
    _dataItemCount = 0;
}

#pragma mark - Adding to queue

- (void)enqueueTelemetryItem:(PREDTelemetryData *)item {
    
    if (!item) {
        // Case 1: Item is nil: Do not enqueue item and abort operation
        PREDLogWarning(@"WARNING: TelemetryItem was nil.");
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.dataItemsOperations, ^{
        typeof(self) strongSelf = weakSelf;
        
        if (strongSelf.isQueueBusy) {
            // Case 2: Channel is in blocked state: Trigger sender, start timer to check after again after a while and abort operation.
            PREDLogDebug(@"The channel is saturated. %@ was dropped.", item.debugDescription);
            if (![strongSelf timerIsRunning]) {
                [strongSelf startTimer];
            }
            return;
        }
        
        // Enqueue item
        NSDictionary *dict = [self dictionaryForTelemetryData:item];
        [strongSelf appendDictionaryToJsonStream:dict];
        
        if (strongSelf->_dataItemCount >= self.maxBatchSize) {
            // Case 3: Max batch count has been reached, so write queue to disk and delete all items.
            [strongSelf persistDataItemQueue];
            
        } else if (strongSelf->_dataItemCount == 1) {
            // Case 4: It is the first item, let's start the timer.
            if (![strongSelf timerIsRunning]) {
                [strongSelf startTimer];
            }
        }
    });
}

#pragma mark - Envelope telemerty items

- (NSDictionary *)dictionaryForTelemetryData:(PREDTelemetryData *) telemetryData {
    
    PREDEnvelope *envelope = [self envelopeForTelemetryData:telemetryData];
    NSDictionary *dict = [envelope serializeToDictionary];
    return dict;
}

- (PREDEnvelope *)envelopeForTelemetryData:(PREDTelemetryData *)telemetryData {
    telemetryData.version = @(PREDSchemaVersion);
    
    PREDData *data = [PREDData new];
    data.baseData = telemetryData;
    data.baseType = telemetryData.dataTypeName;
    
    PREDEnvelope *envelope = [PREDEnvelope new];
    envelope.time = [PREDHelper utcDateString:[NSDate date]];
    envelope.iKey = _telemetryContext.appIdentifier;
    
    envelope.tags = _telemetryContext.contextDictionary;
    envelope.data = data;
    envelope.name = telemetryData.envelopeTypeName;
    
    return envelope;
}

#pragma mark - Serialization Helper

- (NSString *)serializeDictionaryToJSONString:(NSDictionary *)dictionary {
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary options:(NSJSONWritingOptions)0 error:&error];
    if (!data) {
        PREDLogError(@"JSONSerialization error: %@", error.localizedDescription);
        return @"{}";
    } else {
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    }
}

#pragma mark JSON Stream

- (void)appendDictionaryToJsonStream:(NSDictionary *)dictionary {
    if (dictionary) {
        NSString *string = [self serializeDictionaryToJSONString:dictionary];
        
        // Since we can't persist every event right away, we write it to a simple C string.
        // This can then be written to disk by a signal handler in case of a crash.
        pres_appendStringToSafeJsonStream(string, &(PREDSafeJsonEventsString));
        _dataItemCount += 1;
    }
}

void pres_appendStringToSafeJsonStream(NSString *string, char **jsonString) {
    if (jsonString == NULL) { return; }
    
    if (!string) { return; }
    
    if (*jsonString == NULL || strlen(*jsonString) == 0) {
        pres_resetSafeJsonStream(jsonString);
    }
    
    if (string.length == 0) { return; }
    
    char *new_string = NULL;
    // Concatenate old string with new JSON string and add a comma.
    asprintf(&new_string, "%s%.*s\n", *jsonString, (int)MIN(string.length, (NSUInteger)INT_MAX), string.UTF8String);
    free(*jsonString);
    *jsonString = new_string;
}

void pres_resetSafeJsonStream(char **string) {
    if (!string) { return; }
    free(*string);
    *string = strdup("");
}

#pragma mark - Batching

- (NSUInteger)maxBatchSize {
    if(_maxBatchSize <= 0){
        return PREDDefaultMaxBatchSize;
    }
    return _maxBatchSize;
}

- (void)invalidateTimer {
    if ([self timerIsRunning]) {
        dispatch_source_cancel(self.timerSource);
        self.timerSource = nil;
    }
}

-(BOOL)timerIsRunning {
    return self.timerSource != nil;
}

- (void)startTimer {
    // Reset timer, if it is already running
    if ([self timerIsRunning]) {
        [self invalidateTimer];
    }
    
    self.timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.dataItemsOperations);
    dispatch_source_set_timer(self.timerSource, dispatch_walltime(NULL, NSEC_PER_SEC * self.batchInterval), 1ull * NSEC_PER_SEC, 1ull * NSEC_PER_SEC);
    
    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(self.timerSource, ^{
        typeof(self) strongSelf = weakSelf;
        
        if(strongSelf) {
            if (strongSelf->_dataItemCount > 0) {
                [strongSelf persistDataItemQueue];
            } else {
                strongSelf.channelBlocked = NO;
            }
            [strongSelf invalidateTimer];
        }
    });
    
    dispatch_resume(self.timerSource);
}

/**
 * Send a PREDBlockingChannelNotification to the main thread to notify observers that channel can't enqueue new items.
 * This is typically used to trigger sending.
 */
- (void)sendBlockingChannelNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:PREDChannelBlockedNotification
                                                            object:nil
                                                          userInfo:nil];
    });
}

@end

NS_ASSUME_NONNULL_END
