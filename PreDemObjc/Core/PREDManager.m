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
    
    PREDNetworkClient *_networkClient;
    
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
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@events/%@", [[self sharedPREDManager] baseUrl], eventName]]];
    request.HTTPMethod = @"POST";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *err;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:event options:0 error:&err];
    if (err) {
        PREDLogError(@"sys info can not be jsonized");
    }
    [NSURLProtocol setProperty:@YES
                        forKey:@"PREDInternalRequest"
                     inRequest:request];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration];
    NSURLSessionTask *task = [session dataTaskWithRequest:request
                                        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) { NSLog(@"%@", [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil]); }];
    [task resume];
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

-(NSString *_Nonnull) baseUrl{
    return [NSString stringWithFormat:@"%@/v1/%@/", _serverURL, app_id(_appKey)];
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
    
    [self setServerURL:serviceDomain];
    
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

- (void)setServerURL:(NSString *)aServerURL {
    if (!aServerURL) {
        aServerURL = PRED_DEFAULT_URL;
    }
    if (![aServerURL hasPrefix:@"http://"] && ![aServerURL hasPrefix:@"https://"]) {
        aServerURL = [NSString stringWithFormat:@"http://%@", aServerURL];
    }
    
    if (_serverURL != aServerURL) {
        _serverURL = [aServerURL copy];
        
        if (_networkClient) {
            _networkClient.baseURL = [NSURL URLWithString:_serverURL];
        }
    }
}

- (PREDNetworkClient *)networkClient {
    if (!_networkClient) {
        _networkClient = [[PREDNetworkClient alloc] initWithBaseURL:[NSURL URLWithString:self.serverURL]];
    }
    return _networkClient;
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
    _lagManager = [[PREDLagMonitorController alloc] init];
    
    _managersInitialized = YES;
}

- (void)applyConfig:(PREDConfig *)config {
    self.disableCrashManager = !config.crashReportEnabled;
    self.disableHttpMonitor = !config.httpMonitorEnabled;
}

- (void)diagnose:(NSString *)host
        complete:(PREDNetDiagCompleteHandler)complete {
    [PREDNetDiag diagnose:host appKey:app_id(_appKey) complete:complete];
}

- (void)configManager:(PREDConfigManager *)manager didReceivedConfig:(PREDConfig *)config {
    [self applyConfig:config];
}

@end
