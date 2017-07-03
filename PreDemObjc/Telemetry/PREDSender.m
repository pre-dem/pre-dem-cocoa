#import "PREDSender.h"
#import "PREDPersistencePrivate.h"
#import "PREDChannelPrivate.h"
#import "PREDGZIP.h"
#import "PREDPrivate.h"
#import "PREDHTTPOperation.h"
#import "PREDHelper.h"

static char const *kPREDSenderTasksQueueString = "net.hockeyapp.sender.tasksQueue";
static char const *kPREDSenderRequestsCountQueueString = "net.hockeyapp.sender.requestsCount";
static NSUInteger const PREDDefaultRequestLimit = 10;

@interface PREDSender ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation PREDSender

@synthesize runningRequestsCount = _runningRequestsCount;
@synthesize persistence = _persistence;

#pragma mark - Initialize instance

- (instancetype)initWithPersistence:(nonnull PREDPersistence *)persistence serverURL:(nonnull NSURL *)serverURL {
    if ((self = [super init])) {
        _requestsCountQueue = dispatch_queue_create(kPREDSenderRequestsCountQueueString, DISPATCH_QUEUE_CONCURRENT);
        _senderTasksQueue = dispatch_queue_create(kPREDSenderTasksQueueString, DISPATCH_QUEUE_CONCURRENT);
        _maxRequestCount = PREDDefaultRequestLimit;
        _serverURL = serverURL;
        _persistence = persistence;
        [self registerObservers];
    }
    return self;
}

#pragma mark - Handle persistence events

- (void)registerObservers {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    __weak typeof(self) weakSelf = self;
    
    [center addObserverForName:PREDPersistenceSuccessNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *notification) {
                        typeof(self) strongSelf = weakSelf;
                        [strongSelf sendSavedDataAsync];
                    }];
    
    [center addObserverForName:PREDChannelBlockedNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification *notification) {
                        typeof(self) strongSelf = weakSelf;
                        [strongSelf sendSavedDataAsync];
                    }];
}

#pragma mark - Sending

- (void)sendSavedDataAsync {
    dispatch_async(self.senderTasksQueue, ^{
        [self sendSavedData];
    });
}

- (void)sendSavedData {
    @synchronized(self){
        if(_runningRequestsCount < _maxRequestCount){
            _runningRequestsCount++;
            PREDLogDebug(@"Create new sender thread. Current count is %ld", (long) _runningRequestsCount);
        }else{
            return;
        }
    }
    
    NSString *filePath = [self.persistence requestNextFilePath];
    NSData *data = [self.persistence dataAtFilePath:filePath];
    [self sendData:data withFilePath:filePath];
    
}

- (void)sendData:(nonnull NSData *)data withFilePath:(nonnull NSString *)filePath {
    if (data && data.length > 0) {
        NSData *gzippedData = [data gzippedData];
        NSURLRequest *request = [self requestForData:gzippedData];
        
        [self sendRequest:request filePath:filePath];
    } else {
        self.runningRequestsCount -= 1;
        PREDLogDebug(@"Close sender thread due empty package. Current count is %ld", (long) _runningRequestsCount);
        // TODO: Delete data and send next file
    }
}

- (void)sendRequest:(nonnull NSURLRequest *) request filePath:(nonnull NSString *) path {
    if (!path || !request) {return;}
    
    if ([self isURLSessionSupported]) {
        [self sendUsingURLSessionWithRequest:request filePath:path];
    } else {
        [self sendUsingURLConnectionWithRequest:request filePath:path];
    }
}

- (BOOL)isURLSessionSupported {
    id nsurlsessionClass = NSClassFromString(@"NSURLSessionUploadTask");
    BOOL isUrlSessionSupported = (nsurlsessionClass && !PREDHelper.isRunningInAppExtension);
    return isUrlSessionSupported;
}

- (void)sendUsingURLConnectionWithRequest:(nonnull NSURLRequest *)request filePath:(nonnull NSString *)filePath {
    PREDHTTPOperation *operation = [PREDHTTPOperation operationWithRequest:request];
    [operation setCompletion:^(PREDHTTPOperation *operation, NSData *responseData, NSError *error) {
        NSInteger statusCode = [operation.response statusCode];
        [self handleResponseWithStatusCode:statusCode responseData:responseData filePath:filePath error:error];
    }];
    
    [self.operationQueue addOperation:operation];
}

- (void)sendUsingURLSessionWithRequest:(nonnull NSURLRequest *)request filePath:(nonnull NSString *)filePath {
    NSURLSession *session = self.session;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                                                NSInteger statusCode = httpResponse.statusCode;
                                                [self handleResponseWithStatusCode:statusCode responseData:data filePath:filePath error:error];
                                            }];
    [self resumeSessionDataTask:task];
}

- (void)resumeSessionDataTask:(nonnull NSURLSessionDataTask *)sessionDataTask {
    [sessionDataTask resume];
}

- (void)handleResponseWithStatusCode:(NSInteger)statusCode responseData:(nonnull NSData *)responseData filePath:(nonnull NSString *)filePath error:(nonnull NSError *)error {
    self.runningRequestsCount -= 1;
    PREDLogDebug(@"Close sender thread due incoming response. Current count is %ld", (long) _runningRequestsCount);
    
    if (responseData && (responseData.length > 0) && [self shouldDeleteDataWithStatusCode:statusCode]) {
        //we delete data that was either sent successfully or if we have a non-recoverable error
        PREDLogDebug(@"Sent data with status code: %ld", (long) statusCode);
        PREDLogDebug(@"Response data:\n%@", [NSJSONSerialization JSONObjectWithData:responseData options:0 error:nil]);
        [self.persistence deleteFileAtPath:filePath];
        [self sendSavedData];
    } else {
        PREDLogError(@"Sending telemetry data failed");
        PREDLogError(@"Error description: %@", error.localizedDescription);
        [self.persistence giveBackRequestedFilePath:filePath];
    }
}

#pragma mark - Helper

- (NSURLRequest *)requestForData:(nonnull NSData *)data {
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.serverURL];
    request.HTTPMethod = @"POST";
    
    request.HTTPBody = data;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    
    NSDictionary<NSString *,NSString *> *headers = @{@"Charset" : @"UTF-8",
                                                     @"Content-Encoding" : @"gzip",
                                                     @"Content-Type" : @"application/x-json-stream",
                                                     @"Accept-Encoding" : @"gzip"};
    [request setAllHTTPHeaderFields:headers];
    
    [NSURLProtocol setProperty:@YES
                        forKey:@"PREDInternalRequest"
                     inRequest:request];
    
    return request;
}

//some status codes represent recoverable error codes
//we try sending again some point later
- (BOOL)shouldDeleteDataWithStatusCode:(NSInteger)statusCode {
    NSArray<NSNumber *> *recoverableStatusCodes = @[@429, @408, @500, @503, @511];
    
    return ![recoverableStatusCodes containsObject:@(statusCode)];
}

#pragma mark - Getter/Setter

- (NSURLSession *)session {
    if (!_session) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    }
    return _session;
}

- (NSOperationQueue *)operationQueue {
    if (nil == _operationQueue) {
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = PREDDefaultRequestLimit;
    }
    return _operationQueue;
}

- (NSUInteger)runningRequestsCount {
    __block NSUInteger count;
    dispatch_sync(_requestsCountQueue, ^{
        count = _runningRequestsCount;
    });
    return count;
}

- (void)setRunningRequestsCount:(NSUInteger)runningRequestsCount {
    dispatch_sync(_requestsCountQueue, ^{
        _runningRequestsCount = runningRequestsCount;
    });
}

@end
