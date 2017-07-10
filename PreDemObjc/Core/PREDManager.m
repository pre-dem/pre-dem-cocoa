//
//  PREDManager.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PreDemObjc.h"
#import "PREDManagerPrivate.h"
#import "PREDPrivate.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import "PREDVersion.h"
#import "PREDConfigManager.h"
#import "PREDNetDiag.h"
#import "PREDURLProtocol.h"
#import "PREDCrashManager.h"
#import "PREDLagMonitorController.h"

static NSString* app_id(NSString* appKey){
    return [appKey substringToIndex:8];
}

@implementation PREDManager {
    NSString *_appKey;
    
    BOOL _startManagerIsInvoked;
    
    BOOL _managersInitialized;
        
    PREDConfigManager *_configManager;
    
    PREDURLProtocol *_httpManager;
    
    PREDCrashManager *_crashManager;
    
    PREDLagMonitorController *_lagManager;
}


#pragma mark - Public Class Methods

+ (void)startWithAppKey:(nonnull NSString *)appKey
          serviceDomain:(nonnull NSString *)serviceDomain{
    [[self sharedPREDManager] startWithAppKey:appKey serviceDomain:serviceDomain];
}


+ (void)diagnose:(nonnull NSString *)host
        complete:(nonnull PREDNetDiagCompleteHandler)complete{
    [[self sharedPREDManager] diagnose:host complete:complete];
}

+ (void)trackEventWithName:(nonnull NSString *)eventName
                     event:(nonnull NSDictionary*)event{
    if (event == nil || eventName == nil) {
        return;
    }
    
    [[self sharedPREDManager].networkClient postPath:[NSString stringWithFormat:@"events/%@", eventName] parameters:event completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]);
    }];
}

+ (PREDLogLevel)logLevel {
    return PREDLogger.currentLogLevel;
}

+ (void)setLogLevel:(PREDLogLevel)logLevel {
    PREDLogger.currentLogLevel = logLevel;
}

+ (void)setLogHandler:(PREDLogHandler)logHandler {
    [PREDLogger setLogHandler:logHandler];
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
        _managersInitialized = NO;
        
        _networkClient = nil;
        
        _disableCrashManager = NO;
        _disableHttpMonitor = NO;
        _disableLagMonitor = NO;
        
        _startManagerIsInvoked = NO;
    }
    return self;
}


- (void)startWithAppKey:(NSString *)appKey serviceDomain:(NSString *)serviceDomain {
    _appKey = [appKey copy];
    
    [self initNetworkClient:serviceDomain];
    
    [self initializeModules];
    
    [self applyConfig:[_configManager getConfigWithAppKey:appKey]];
    
    [self startManager];
}

- (void)startManager {
    if (_startManagerIsInvoked) {
        PREDLogWarning(@"startManager should only be invoked once! This call is ignored.");
        return;
    }
    
    PREDLogDebug(@"Starting PREDManager");
    _startManagerIsInvoked = YES;
    
    // start CrashManager
    if (![self isCrashManagerDisabled]) {
        PREDLogDebug(@"Starting CrashManager");
        
        [_crashManager startManager];
    }
    
    if (!self.isHttpMonitorDisabled) {
        PREDLogDebug(@"Starting HttpManager");

        [_httpManager enableHTTPDem];
    }
    
    if (!self.isLagMonitorDisabled) {
        PREDLogDebug(@"Starting LagManager");
        
        [_lagManager startMonitor];
    }
}

#warning todo
- (void)setDisableCrashManager:(BOOL)disableCrashManager {
    
}

- (void)setDisableHttpMonitor:(BOOL)disableHttpMonitor {
    _disableHttpMonitor = disableHttpMonitor;
    if (disableHttpMonitor) {
        [_httpManager disableHTTPDem];
    } else {
        [_httpManager enableHTTPDem];
    }
}

- (void)setDisableLagMonitor:(BOOL)disableLagMonitor {
    _disableLagMonitor = disableLagMonitor;
    if (disableLagMonitor) {
        [_lagManager endMonitor];
    } else {
        [_lagManager startMonitor];
    }
}

- (void)initNetworkClient:(NSString *)aServerURL {
    if (!aServerURL) {
        aServerURL = PRED_DEFAULT_URL;
    }
    if (![aServerURL hasPrefix:@"http://"] && ![aServerURL hasPrefix:@"https://"]) {
        aServerURL = [NSString stringWithFormat:@"http://%@", aServerURL];
    }
    
    aServerURL = [NSString stringWithFormat:@"%@/v1/%@/", aServerURL, app_id(_appKey)];
    
    _networkClient = [[PREDNetworkClient alloc] initWithBaseURL:[NSURL URLWithString:aServerURL]];
}

- (void)initializeModules {
    if (_managersInitialized) {
        PREDLogWarning(@"The SDK should only be initialized once! This call is ignored.");
        return;
    }
    
    _startManagerIsInvoked = NO;
    
    PREDLogDebug(@"Setup CrashManager");
    _crashManager = [[PREDCrashManager alloc]
                     initWithAppIdentifier:app_id(_appKey)
                     networkClient:[self networkClient]];
    _httpManager = [[PREDURLProtocol alloc] init];
    _configManager = [[PREDConfigManager alloc] init];
    _configManager.delegate = self;
    _lagManager = [[PREDLagMonitorController alloc] initWithAppId:app_id(_appKey) networkClient:[self networkClient]];
    
    _managersInitialized = YES;
}

- (void)applyConfig:(PREDConfig *)config {
    self.disableCrashManager = !config.crashReportEnabled;
    self.disableHttpMonitor = !config.httpMonitorEnabled;
}

- (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [PREDNetDiag diagnose:host appKey:app_id(_appKey) netClient:_networkClient complete:complete];
}

- (void)configManager:(PREDConfigManager *)manager didReceivedConfig:(PREDConfig *)config {
    [self applyConfig:config];
}

@end
