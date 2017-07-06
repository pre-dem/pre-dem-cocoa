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

static NSString* app_id(NSString* appKey){
    return [appKey substringToIndex:8];
}

@implementation PREDManager {
    NSString *_appKey;
    
    BOOL _startManagerIsInvoked;
    
    BOOL _managersInitialized;
    
    PREDNetworkClient *_hockeyAppClient;
    
    PREDConfigManager *_configManager;
}


#pragma mark - Public Class Methods

+ (PREDManager *)sharedPREDManager {
    static PREDManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[PREDManager alloc] init];
    });
    
    return sharedInstance;
}

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

#pragma mark - Private Instance Methods

- (instancetype)init {
    if ((self = [super init])) {
        _managersInitialized = NO;
        
        _hockeyAppClient = nil;
        
        _disableCrashManager = NO;
        
        _startManagerIsInvoked = NO;
        
        _configManager = [[PREDConfigManager alloc] init];
        _configManager.delegate = self;
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
    
    // Fix bug where Application Support directory was encluded from backup
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    [PREDHelper fixBackupAttributeForURL:appSupportURL];
    
    if (![self isSetUpOnMainThread]) return;
    
    PREDLogDebug(@"Starting PREDManager");
    _startManagerIsInvoked = YES;
    
    // start CrashManager
    if (![self isCrashManagerDisabled]) {
        PREDLogDebug(@"Start CrashManager");
        
        [_crashManager startManager];
    }
    
    // App Extensions can only use PREDCrashManager, so ignore all others automatically
    if (PREDHelper.isRunningInAppExtension) {
        return;
    }
    
    
    if (!self.isHttpMonitorDisabled) {
        [PREDURLProtocol enableHTTPDem];
    }
}

- (void)setDisableHttpMonitor:(BOOL)disableHttpMonitor {
    _disableHttpMonitor = disableHttpMonitor;
    if (disableHttpMonitor) {
        [PREDURLProtocol disableHTTPDem];
    } else {
        [PREDURLProtocol enableHTTPDem];
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
        
        if (_hockeyAppClient) {
            _hockeyAppClient.baseURL = [NSURL URLWithString:_serverURL];
        }
    }
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

#pragma mark - Private Instance Methods

- (PREDNetworkClient *)hockeyAppClient {
    if (!_hockeyAppClient) {
        _hockeyAppClient = [[PREDNetworkClient alloc] initWithBaseURL:[NSURL URLWithString:self.serverURL]];
    }
    return _hockeyAppClient;
}

- (void)logPingMessageForStatusCode:(NSInteger)statusCode {
    switch (statusCode) {
        case 400:
            PREDLogError(@"App ID not found");
            break;
        case 201:
            PREDLogDebug(@"Ping accepted.");
            break;
        case 200:
            PREDLogDebug(@"Ping accepted. Server already knows.");
            break;
        default:
            PREDLogError(@"Unknown error");
            break;
    }
}

- (BOOL)isSetUpOnMainThread {
    NSString *errorString = @"PreDemObjc has to be setup on the main thread!";
    
    if (!NSThread.isMainThread) {
        PREDLogError(@"%@", errorString);
        NSAssert(NSThread.isMainThread, errorString);
        return NO;
    }
    
    return YES;
}

- (void)initializeModules {
    if (_managersInitialized) {
        PREDLogWarning(@"The SDK should only be initialized once! This call is ignored.");
        return;
    }
    
    
    if (![self isSetUpOnMainThread]) return;
    
    _startManagerIsInvoked = NO;
    
    PREDLogDebug(@"Setup CrashManager");
    _crashManager = [[PREDCrashManager alloc]
                     initWithAppIdentifier:app_id(_appKey)
                     hockeyAppClient:[self hockeyAppClient]];
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

#pragma mark - Private Class Methods

-(nonnull NSString*) baseUrl{
    return [NSString stringWithFormat:@"%@/v1/%@/", _serverURL, app_id(_appKey)];
}

@end
