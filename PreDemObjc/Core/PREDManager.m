//
//  PREDManager.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PreDemObjc.h"
#import "PREDManagerPrivate.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import "PREDVersion.h"
#import "PREDConfigManager.h"
#import "PREDNetDiag.h"
#import "PREDURLProtocol.h"
#import "PREDCrashManager.h"
#import "PREDLagMonitorController.h"
#import "PREDLogger.h"
#import "PREDError.h"
#import "PREDLoggerPrivate.h"
#import "PREDSender.h"

static NSString* app_id(NSString* appKey){
    if (appKey.length >= PREDAppIdLength) {
        return [appKey substringToIndex:PREDAppIdLength];
    } else {
        return appKey;
    }
}

@implementation PREDManager {
    PREDConfigManager *_configManager;
    
    PREDCrashManager *_crashManager;
    
    PREDLagMonitorController *_lagManager;
    
    PREDPersistence *_persistence;
    
    PREDSender *_sender;
}


#pragma mark - Public Class Methods

+ (void)startWithAppKey:(NSString *)appKey
          serviceDomain:(NSString *)serviceDomain
                  error:(NSError **)error {
    dispatch_async(dispatch_get_global_queue(0, DISPATCH_QUEUE_PRIORITY_DEFAULT), ^{
        [[self sharedPREDManager] startWithAppKey:appKey serviceDomain:serviceDomain error:error];
    });
}


+ (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [[self sharedPREDManager] diagnose:host complete:complete];
}

+ (void)trackEventWithName:(NSString *)eventName
                     event:(NSDictionary *)event {
    if (event == nil || eventName == nil) {
        return;
    }
    [[self sharedPREDManager]->_persistence persistCustomEventWithName:eventName events:@[event]];
}

+ (void)trackEventsWithName:(NSString *)eventName
                     events:(NSArray<NSDictionary *>*)events{
    if (events == nil || events.count == 0 || eventName == nil) {
        return;
    }
    
    [[self sharedPREDManager]->_persistence persistCustomEventWithName:eventName events:events];
}

+ (NSString *)tag {
    return PREDHelper.tag;
}

+ (void)setTag:(NSString *)tag {
    PREDHelper.tag = tag;
}

+ (NSString *)version {
    return [PREDVersion getSDKVersion];
}

+ (NSString *)build {
    return [PREDVersion getSDKBuild];
}

#pragma mark - Private Methods

+ (PREDManager *)sharedPREDManager {
    static PREDManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[PREDManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _enableCrashManager = YES;
        _enableHttpMonitor = YES;
        _enableLagMonitor = YES;
        _persistence = [[PREDPersistence alloc] init];
    }
    return self;
}

- (void)startWithAppKey:(NSString *)appKey serviceDomain:(NSString *)serviceDomain error:(NSError **)error {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _appKey = appKey;

        [self initSenderWithDomain:serviceDomain appKey:appKey error:error];
        if (error != NULL && *error) {
            return;
        }
        
        [self initializeModules];
        
        [self applyConfig:[_configManager getConfig]];
        
        [self startManager];
        
        [self registerObservers];
        
        [_sender sendAllSavedData];
    });
}

- (void)initSenderWithDomain:(NSString *)aServerURL appKey:(NSString *)appKey error:(NSError **)error {
    if (!aServerURL.length) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidServiceDomain description:@"you must specify server domain"];
        }
        return;
    }
    if (appKey.length < PREDAppIdLength) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInvalidAppKey description:@"the length of your app key must be longer than %d", PREDAppIdLength];
        }
        return;
    }
    if (![aServerURL hasPrefix:@"http://"] && ![aServerURL hasPrefix:@"https://"]) {
        aServerURL = [NSString stringWithFormat:@"http://%@", aServerURL];
    }
    
    aServerURL = [NSString stringWithFormat:@"%@/v1/%@/", aServerURL, app_id(appKey)];
    
    _sender = [[PREDSender alloc] initWithPersistence:_persistence baseUrl:[NSURL URLWithString:aServerURL]];
}

- (void)initializeModules {
    _crashManager = [[PREDCrashManager alloc]
                     initWithPersistence:_persistence];
    [PREDURLProtocol setPersistence:_persistence];
    _configManager = [[PREDConfigManager alloc] initWithPersistence:_persistence];
    _lagManager = [[PREDLagMonitorController alloc] initWithPersistence:_persistence];
    [PREDLogger setPersistence:_persistence];
}

- (void)applyConfig:(PREDConfig *)config {
    self.enableCrashManager = config.crashReportEnabled;
    self.enableHttpMonitor = config.httpMonitorEnabled;
    self.enableLagMonitor = config.lagMonitorEnabled;
    _crashManager.enableOnDeviceSymbolication = config.onDeviceSymbolicationEnabled;
}

- (void)startManager {
    // start CrashManager
    if (self.isCrashManagerEnabled) {
        PREDLogDebug(@"Starting CrashManager");
        
        [_crashManager startManager];
    }
    
    if (self.isHttpMonitorEnabled) {
        PREDLogDebug(@"Starting HttpManager");
        
        [PREDURLProtocol enableHTTPMonitor];
    }
    
    if (self.isLagMonitorEnabled) {
        PREDLogDebug(@"Starting LagManager");
        
        [_lagManager startMonitor];
    }
}

- (void)registerObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configRefreshed:) name:kPREDConfigRefreshedNotification object:nil];
}

- (void)setEnableCrashManager:(BOOL)enableCrashManager {
    if (_enableCrashManager == enableCrashManager) {
        return;
    }
    _enableCrashManager = enableCrashManager;
    if (enableCrashManager) {
        [_crashManager startManager];
    } else {
        [_crashManager stopManager];
    }
}

- (void)setEnableHttpMonitor:(BOOL)enableHttpMonitor {
    if (_enableHttpMonitor == enableHttpMonitor) {
        return;
    }
    _enableHttpMonitor = enableHttpMonitor;
    if (enableHttpMonitor) {
        [PREDURLProtocol enableHTTPMonitor];
    } else {
        [PREDURLProtocol disableHTTMonitor];
    }
}

- (void)setEnableLagMonitor:(BOOL)enableLagMonitor {
    if (_enableLagMonitor == enableLagMonitor) {
        return;
    }
    _enableLagMonitor = enableLagMonitor;
    if (enableLagMonitor) {
        [_lagManager startMonitor];
    } else {
        [_lagManager endMonitor];
    }
}

- (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [PREDNetDiag diagnose:host persistence:_persistence complete:complete];
}

- (void)configRefreshed:(NSNotification *)noty {
    NSDictionary *dic = noty.userInfo[kPREDConfigRefreshedNotificationConfigKey];
    PREDConfig *config = [PREDConfig configWithDic:dic];
    [self applyConfig:config];
}

@end
