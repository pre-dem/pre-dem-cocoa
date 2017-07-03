#import "PreDemObjc.h"
#import "PREDMetricsManager.h"
#import "PREDTelemetryContext.h"
#import "PREDMetricsManagerPrivate.h"
#import "PREDHelper.h"
#import "PREDPrivate.h"
#import "PREDChannel.h"
#import "PREDEventData.h"
#import "PREDSession.h"
#import "PREDSessionState.h"
#import "PREDSessionStateData.h"
#import "PREDPersistence.h"
#import "PREDBaseManagerPrivate.h"
#import "PREDSender.h"

NSString *const kPREDApplicationWasLaunched = @"PREDApplicationWasLaunched";

static char *const kPREDMetricsEventQueue = "net.hockeyapp.telemetryEventQueue";

static NSString *const kPREDSessionFileType = @"plist";
static NSString *const kPREDApplicationDidEnterBackgroundTime = @"PREDApplicationDidEnterBackgroundTime";

static NSString *const PREDMetricsBaseURLString = @"https://gate.hockeyapp.net/";
static NSString *const PREDMetricsURLPathString = @"v2/track";

@interface PREDMetricsManager ()

@property (nonatomic, strong) id<NSObject> appWillEnterForegroundObserver;
@property (nonatomic, strong) id<NSObject> appDidEnterBackgroundObserver;

@end

@implementation PREDMetricsManager

@synthesize channel = _channel;
@synthesize telemetryContext = _telemetryContext;
@synthesize persistence = _persistence;
@synthesize serverURL = _serverURL;
@synthesize userDefaults = _userDefaults;

#pragma mark - Create & start instance

- (instancetype)init {
    if ((self = [super init])) {
        _disabled = NO;
        _metricsEventQueue = dispatch_queue_create(kPREDMetricsEventQueue, DISPATCH_QUEUE_CONCURRENT);
        _appBackgroundTimeBeforeSessionExpires = 20;
        _serverURL = [NSString stringWithFormat:@"%@%@", PREDMetricsBaseURLString, PREDMetricsURLPathString];
    }
    return self;
}

- (instancetype)initWithChannel:(PREDChannel *)channel telemetryContext:(PREDTelemetryContext *)telemetryContext persistence:(PREDPersistence *)persistence userDefaults:(NSUserDefaults *)userDefaults {
    if ((self = [self init])) {
        _channel = channel;
        _telemetryContext = telemetryContext;
        _persistence = persistence;
        _userDefaults = userDefaults;
    }
    return self;
}

- (void)startManager {
    self.sender = [[PREDSender alloc] initWithPersistence:self.persistence serverURL:[NSURL URLWithString:self.serverURL]];
    [self.sender sendSavedDataAsync];
    [self startNewSessionWithId:PREDHelper.UUID];
    [self registerObservers];
}

#pragma mark - Configuration

- (void)setDisabled:(BOOL)disabled {
    if (_disabled == disabled) { return; }
    
    if (disabled) {
        [self unregisterObservers];
    } else {
        [self registerObservers];
    }
    _disabled = disabled;
}

#pragma mark - Sessions

- (void)registerObservers {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    __weak typeof(self) weakSelf = self;
    
    if (nil == self.appDidEnterBackgroundObserver) {
        self.appDidEnterBackgroundObserver = [nc addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                             object:nil
                                                              queue:NSOperationQueue.mainQueue
                                                         usingBlock:^(NSNotification *note) {
                                                             typeof(self) strongSelf = weakSelf;
                                                             [strongSelf updateDidEnterBackgroundTime];
                                                         }];
    }
    if (nil == self.appWillEnterForegroundObserver) {
        self.appWillEnterForegroundObserver = [nc addObserverForName:UIApplicationWillEnterForegroundNotification
                                                              object:nil
                                                               queue:NSOperationQueue.mainQueue
                                                          usingBlock:^(NSNotification *note) {
                                                              typeof(self) strongSelf = weakSelf;
                                                              [strongSelf startNewSessionIfNeeded];
                                                          }];
    }
}

- (void)unregisterObservers {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.appDidEnterBackgroundObserver = nil;
    self.appWillEnterForegroundObserver = nil;
}

- (void)updateDidEnterBackgroundTime {
    [self.userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kPREDApplicationDidEnterBackgroundTime];
    if(PREDHelper.isPreiOS8Environment) {
        // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
        [self.userDefaults synchronize];
    }
}

- (void)startNewSessionIfNeeded {
    double appDidEnterBackgroundTime = [self.userDefaults doubleForKey:kPREDApplicationDidEnterBackgroundTime];
    // Add safeguard in case this returns a negative value
    if(appDidEnterBackgroundTime < 0) {
        appDidEnterBackgroundTime = 0;
        [self.userDefaults setDouble:0 forKey:kPREDApplicationDidEnterBackgroundTime];
        if(PREDHelper.isPreiOS8Environment) {
            // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
            [self.userDefaults synchronize];
        }
    }
    double timeSinceLastBackground = [[NSDate date] timeIntervalSince1970] - appDidEnterBackgroundTime;
    if (timeSinceLastBackground > self.appBackgroundTimeBeforeSessionExpires) {
        [self startNewSessionWithId:PREDHelper.UUID];
    }
}

- (void)startNewSessionWithId:(NSString *)sessionId {
    PREDSession *newSession = [self createNewSessionWithId:sessionId];
    [self.telemetryContext setSessionId:newSession.sessionId];
    [self.telemetryContext setIsFirstSession:newSession.isFirst];
    [self.telemetryContext setIsNewSession:newSession.isNew];
    [self trackSessionWithState:PREDSessionState_start];
}

- (PREDSession *)createNewSessionWithId:(NSString *)sessionId {
    PREDSession *session = [PREDSession new];
    session.sessionId = sessionId;
    session.isNew = @"true";
    
    if (![self.userDefaults boolForKey:kPREDApplicationWasLaunched]) {
        session.isFirst = @"true";
        [self.userDefaults setBool:YES forKey:kPREDApplicationWasLaunched];
        if(PREDHelper.isPreiOS8Environment) {
            // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
            [self.userDefaults synchronize];
        }
    } else {
        session.isFirst = @"false";
    }
    return session;
}

#pragma mark - Track telemetry

#pragma mark Sessions

- (void)trackSessionWithState:(PREDSessionState)state {
    if (self.disabled) {
        PREDLogDebug(@"PREDMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    PREDSessionStateData *sessionStateData = [PREDSessionStateData new];
    sessionStateData.state = state;
    [self.channel enqueueTelemetryItem:sessionStateData];
}

#pragma mark Events

- (void)trackEventWithName:(nonnull NSString *)eventName {
    if (!eventName) { return; }
    if (self.disabled) {
        PREDLogDebug(@"PREDMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.metricsEventQueue, ^{
        typeof(self) strongSelf = weakSelf;
        PREDEventData *eventData = [PREDEventData new];
        [eventData setName:eventName];
        [strongSelf trackDataItem:eventData];
    });
}

- (void)trackEventWithName:(nonnull NSString *)eventName properties:(nullable NSDictionary<NSString *, NSString *> *)properties measurements:(nullable NSDictionary<NSString *, NSNumber *> *)measurements {
    if (!eventName) { return; }
    if (self.disabled) {
        PREDLogDebug(@"PREDMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.metricsEventQueue, ^{
        typeof(self) strongSelf = weakSelf;
        PREDEventData *eventData = [PREDEventData new];
        [eventData setName:eventName];
        [eventData setProperties:properties];
        [eventData setMeasurements:measurements];
        [strongSelf trackDataItem:eventData];
    });
}

#pragma mark Track DataItem

- (void)trackDataItem:(PREDTelemetryData *)dataItem {
    if (self.disabled) {
        PREDLogDebug(@"PREDMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    
    [self.channel enqueueTelemetryItem:dataItem];
}

#pragma mark - Custom getter

- (PREDChannel *)channel {
    if (!_channel) {
        _channel = [[PREDChannel alloc] initWithTelemetryContext:self.telemetryContext persistence:self.persistence];
    }
    return _channel;
}

- (PREDTelemetryContext *)telemetryContext {
    if (!_telemetryContext) {
        _telemetryContext = [[PREDTelemetryContext alloc] initWithAppIdentifier:self.appIdentifier persistence:self.persistence];
    }
    return _telemetryContext;
}

- (PREDPersistence *)persistence {
    if (!_persistence) {
        _persistence = [PREDPersistence new];
    }
    return _persistence;
}

- (NSUserDefaults *)userDefaults {
    if (!_userDefaults) {
        _userDefaults = [NSUserDefaults standardUserDefaults];
    }
    return _userDefaults;
}

@end
