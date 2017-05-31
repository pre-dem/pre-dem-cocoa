#import "PreSniffSDKPrivate.h"
#import "PRESChannelPrivate.h"
#import "PRESHelper.h"
#import "PRESTelemetryContext.h"
#import "PRESTelemetryData.h"
#import "PreSniffSDKPrivate.h"
#import "PRESEnvelope.h"
#import "PRESData.h"
#import "PRESDevice.h"
#import "PRESPersistencePrivate.h"

static char *const PRESDataItemsOperationsQueue = "net.hockeyapp.senderQueue";
char *PRESSafeJsonEventsString;

NSString *const PRESChannelBlockedNotification = @"PRESChannelBlockedNotification";

static NSInteger const PRESDefaultMaxBatchSize  = 50;
static NSInteger const PRESDefaultBatchInterval = 15;
static NSInteger const PRESSchemaVersion = 2;

static NSInteger const PRESDebugMaxBatchSize = 5;
static NSInteger const PRESDebugBatchInterval = 3;

NS_ASSUME_NONNULL_BEGIN

@implementation PRESChannel

@synthesize persistence = _persistence;
@synthesize channelBlocked = _channelBlocked;

#pragma mark - Initialisation

- (instancetype)init {
  if (self = [super init]) {
    pres_resetSafeJsonStream(&PRESSafeJsonEventsString);
    _dataItemCount = 0;
    if (pres_isDebuggerAttached()) {
      _maxBatchSize = PRESDebugMaxBatchSize;
      _batchInterval = PRESDebugBatchInterval;
    } else {
      _maxBatchSize = PRESDefaultMaxBatchSize;
      _batchInterval = PRESDefaultBatchInterval;
    }
    dispatch_queue_t serialQueue = dispatch_queue_create(PRESDataItemsOperationsQueue, DISPATCH_QUEUE_SERIAL);
    _dataItemsOperations = serialQueue;
  }
  return self;
}

- (instancetype)initWithTelemetryContext:(PRESTelemetryContext *)telemetryContext persistence:(PRESPersistence *)persistence {
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
  if (!PRESSafeJsonEventsString || strlen(PRESSafeJsonEventsString) == 0) {
    return;
  }
  
  NSData *bundle = [NSData dataWithBytes:PRESSafeJsonEventsString length:strlen(PRESSafeJsonEventsString)];
  [self.persistence persistBundle:bundle];
  
  // Reset both, the async-signal-safe and item counter.
  [self resetQueue];
}

- (void)resetQueue {
  pres_resetSafeJsonStream(&PRESSafeJsonEventsString);
  _dataItemCount = 0;
}

#pragma mark - Adding to queue

- (void)enqueueTelemetryItem:(PRESTelemetryData *)item {
  
  if (!item) {
    // Case 1: Item is nil: Do not enqueue item and abort operation
    BITHockeyLogWarning(@"WARNING: TelemetryItem was nil.");
    return;
  }
  
  __weak typeof(self) weakSelf = self;
  dispatch_async(self.dataItemsOperations, ^{
    typeof(self) strongSelf = weakSelf;
    
    if (strongSelf.isQueueBusy) {
      // Case 2: Channel is in blocked state: Trigger sender, start timer to check after again after a while and abort operation.
      BITHockeyLogDebug(@"INFO: The channel is saturated. %@ was dropped.", item.debugDescription);
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

- (NSDictionary *)dictionaryForTelemetryData:(PRESTelemetryData *) telemetryData {
  
  PRESEnvelope *envelope = [self envelopeForTelemetryData:telemetryData];
  NSDictionary *dict = [envelope serializeToDictionary];
  return dict;
}

- (PRESEnvelope *)envelopeForTelemetryData:(PRESTelemetryData *)telemetryData {
  telemetryData.version = @(PRESSchemaVersion);
  
  PRESData *data = [PRESData new];
  data.baseData = telemetryData;
  data.baseType = telemetryData.dataTypeName;
  
  PRESEnvelope *envelope = [PRESEnvelope new];
  envelope.time = pres_utcDateString([NSDate date]);
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
    BITHockeyLogError(@"ERROR: JSONSerialization error: %@", error.localizedDescription);
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
    pres_appendStringToSafeJsonStream(string, &(PRESSafeJsonEventsString));
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
    return PRESDefaultMaxBatchSize;
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
 * Send a PRESHockeyBlockingChannelNotification to the main thread to notify observers that channel can't enqueue new items.
 * This is typically used to trigger sending.
 */
- (void)sendBlockingChannelNotification {
  dispatch_async(dispatch_get_main_queue(), ^{
    [[NSNotificationCenter defaultCenter] postNotificationName:PRESChannelBlockedNotification
                                                        object:nil
                                                      userInfo:nil];
  });
}

@end

NS_ASSUME_NONNULL_END
