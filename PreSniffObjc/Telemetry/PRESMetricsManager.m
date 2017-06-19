#import "PreSniffObjc.h"
#import "PRESMetricsManager.h"
#import "PRESTelemetryContext.h"
#import "PRESMetricsManagerPrivate.h"
#import "PRESHelper.h"
#import "PRESPrivate.h"
#import "PRESChannel.h"
#import "PRESEventData.h"
#import "PRESSession.h"
#import "PRESSessionState.h"
#import "PRESSessionStateData.h"
#import "PRESPersistence.h"
#import "PRESBaseManagerPrivate.h"
#import "PRESSender.h"

NSString *const kPRESApplicationWasLaunched = @"PRESApplicationWasLaunched";

static char *const kPRESMetricsEventQueue = "net.hockeyapp.telemetryEventQueue";

static NSString *const kPRESSessionFileType = @"plist";
static NSString *const kPRESApplicationDidEnterBackgroundTime = @"PRESApplicationDidEnterBackgroundTime";

static NSString *const PRESMetricsBaseURLString = @"https://gate.hockeyapp.net/";
static NSString *const PRESMetricsURLPathString = @"v2/track";

@interface PRESMetricsManager ()

@property (nonatomic, strong) id<NSObject> appWillEnterForegroundObserver;
@property (nonatomic, strong) id<NSObject> appDidEnterBackgroundObserver;

@end

@implementation PRESMetricsManager

@synthesize channel = _channel;
@synthesize telemetryContext = _telemetryContext;
@synthesize persistence = _persistence;
@synthesize serverURL = _serverURL;
@synthesize userDefaults = _userDefaults;

#pragma mark - Create & start instance

- (instancetype)init {
    if ((self = [super init])) {
        _disabled = NO;
        _metricsEventQueue = dispatch_queue_create(kPRESMetricsEventQueue, DISPATCH_QUEUE_CONCURRENT);
        _appBackgroundTimeBeforeSessionExpires = 20;
        _serverURL = [NSString stringWithFormat:@"%@%@", PRESMetricsBaseURLString, PRESMetricsURLPathString];
    }
    return self;
}

- (instancetype)initWithChannel:(PRESChannel *)channel telemetryContext:(PRESTelemetryContext *)telemetryContext persistence:(PRESPersistence *)persistence userDefaults:(NSUserDefaults *)userDefaults {
    if ((self = [self init])) {
        _channel = channel;
        _telemetryContext = telemetryContext;
        _persistence = persistence;
        _userDefaults = userDefaults;
    }
    return self;
}

- (void)startManager {
    self.sender = [[PRESSender alloc] initWithPersistence:self.persistence serverURL:[NSURL URLWithString:self.serverURL]];
    [self.sender sendSavedDataAsync];
    [self startNewSessionWithId:pres_UUID()];
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
    [self.userDefaults setDouble:[[NSDate date] timeIntervalSince1970] forKey:kPRESApplicationDidEnterBackgroundTime];
    if(pres_isPreiOS8Environment()) {
        // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
        [self.userDefaults synchronize];
    }
}

- (void)startNewSessionIfNeeded {
    double appDidEnterBackgroundTime = [self.userDefaults doubleForKey:kPRESApplicationDidEnterBackgroundTime];
    // Add safeguard in case this returns a negative value
    if(appDidEnterBackgroundTime < 0) {
        appDidEnterBackgroundTime = 0;
        [self.userDefaults setDouble:0 forKey:kPRESApplicationDidEnterBackgroundTime];
        if(pres_isPreiOS8Environment()) {
            // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
            [self.userDefaults synchronize];
        }
    }
    double timeSinceLastBackground = [[NSDate date] timeIntervalSince1970] - appDidEnterBackgroundTime;
    if (timeSinceLastBackground > self.appBackgroundTimeBeforeSessionExpires) {
        [self startNewSessionWithId:pres_UUID()];
    }
}

- (void)startNewSessionWithId:(NSString *)sessionId {
    PRESSession *newSession = [self createNewSessionWithId:sessionId];
    [self.telemetryContext setSessionId:newSession.sessionId];
    [self.telemetryContext setIsFirstSession:newSession.isFirst];
    [self.telemetryContext setIsNewSession:newSession.isNew];
    [self trackSessionWithState:PRESSessionState_start];
}

- (PRESSession *)createNewSessionWithId:(NSString *)sessionId {
    PRESSession *session = [PRESSession new];
    session.sessionId = sessionId;
    session.isNew = @"true";
    
    if (![self.userDefaults boolForKey:kPRESApplicationWasLaunched]) {
        session.isFirst = @"true";
        [self.userDefaults setBool:YES forKey:kPRESApplicationWasLaunched];
        if(pres_isPreiOS8Environment()) {
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

- (void)trackSessionWithState:(PRESSessionState)state {
    if (self.disabled) {
        PRESLogDebug(@"PRESMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    PRESSessionStateData *sessionStateData = [PRESSessionStateData new];
    sessionStateData.state = state;
    [self.channel enqueueTelemetryItem:sessionStateData];
}

#pragma mark Events

- (void)trackEventWithName:(nonnull NSString *)eventName {
    if (!eventName) { return; }
    if (self.disabled) {
        PRESLogDebug(@"PRESMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.metricsEventQueue, ^{
        typeof(self) strongSelf = weakSelf;
        PRESEventData *eventData = [PRESEventData new];
        [eventData setName:eventName];
        [strongSelf trackDataItem:eventData];
    });
}

- (void)trackEventWithName:(nonnull NSString *)eventName properties:(nullable NSDictionary<NSString *, NSString *> *)properties measurements:(nullable NSDictionary<NSString *, NSNumber *> *)measurements {
    if (!eventName) { return; }
    if (self.disabled) {
        PRESLogDebug(@"PRESMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(self.metricsEventQueue, ^{
        typeof(self) strongSelf = weakSelf;
        PRESEventData *eventData = [PRESEventData new];
        [eventData setName:eventName];
        [eventData setProperties:properties];
        [eventData setMeasurements:measurements];
        [strongSelf trackDataItem:eventData];
    });
}

#pragma mark Track DataItem

- (void)trackDataItem:(PRESTelemetryData *)dataItem {
    if (self.disabled) {
        PRESLogDebug(@"PRESMetricsManager is disabled, therefore this tracking call was ignored.");
        return;
    }
    
    [self.channel enqueueTelemetryItem:dataItem];
}

#pragma mark - Custom getter

- (PRESChannel *)channel {
    if (!_channel) {
        _channel = [[PRESChannel alloc] initWithTelemetryContext:self.telemetryContext persistence:self.persistence];
    }
    return _channel;
}

- (PRESTelemetryContext *)telemetryContext {
    if (!_telemetryContext) {
        _telemetryContext = [[PRESTelemetryContext alloc] initWithAppIdentifier:self.appIdentifier persistence:self.persistence];
    }
    return _telemetryContext;
}

- (PRESPersistence *)persistence {
    if (!_persistence) {
        _persistence = [PRESPersistence new];
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
