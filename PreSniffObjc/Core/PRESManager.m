/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *         Kent Sutherland
 *
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import "PreSniffObjc.h"
#import "PRESPrivate.h"
#import "PRESBaseManagerPrivate.h"

#import "PRESHelper.h"
#import "PRESNetworkClient.h"
#import "PRESKeychainUtils.h"
#import "PRESVersion.h"

#include <stdint.h>
#import "PRESConfigManager.h"
#import "PRESNetDiag.h"

typedef struct {
    uint8_t       info_version;
    const char    hockey_version[16];
    const char    hockey_build[16];
} bitstadium_info_t;


#import "PRESCrashManagerPrivate.h"
#import "PRESMetricsManagerPrivate.h"
#import "PRESCategoryContainer.h"
#import "PRESURLProtocol.h"

@interface PRESManager ()

- (BOOL)shouldUseLiveIdentifier;

@end


@implementation PRESManager {
    NSString *_appIdentifier;
    NSString *_liveIdentifier;
    
    BOOL _validAppIdentifier;
    
    BOOL _startManagerIsInvoked;
    
    BOOL _managersInitialized;
    
    PRESNetworkClient *_hockeyAppClient;
    
    PRESConfig *_config;
}

#pragma mark - Private Class Methods

- (BOOL)checkValidityOfAppIdentifier:(NSString *)identifier {
    BOOL result = NO;
    
    if (identifier) {
        NSCharacterSet *hexSet = [NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"];
        NSCharacterSet *inStringSet = [NSCharacterSet characterSetWithCharactersInString:identifier];
        result = ([identifier length] == 32) && ([hexSet isSupersetOfSet:inStringSet]);
    }
    
    return result;
}

- (void)logInvalidIdentifier:(NSString *)environment {
    if (self.appEnvironment != PRESEnvironmentAppStore) {
        if ([environment isEqualToString:@"liveIdentifier"]) {
            PRESLogWarning(@"[PreSniffObjc] WARNING: The liveIdentifier is invalid! The SDK will be disabled when deployed to the App Store without setting a valid app identifier!");
        } else {
            PRESLogError(@"[PreSniffObjc] ERROR: The %@ is invalid! Please use the PreSniff app identifier you find on the apps website on PreSniff! The SDK is disabled!", environment);
        }
    }
}


#pragma mark - Public Class Methods

+ (PRESManager *)sharedPRESManager {
    static PRESManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [PRESManager alloc];
        sharedInstance = [sharedInstance init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _serverURL = PRESHOCKEYSDK_URL;
        _delegate = nil;
        _managersInitialized = NO;
        
        _hockeyAppClient = nil;
        
        _disableCrashManager = NO;
        _disableMetricsManager = NO;
        
        _appEnvironment = pres_currentAppEnvironment();
        _startManagerIsInvoked = NO;
        
        _liveIdentifier = nil;
        _installString = pres_appAnonID(NO);
        _disableInstallTracking = NO;
        
        [self performSelector:@selector(validateStartManagerIsInvoked) withObject:nil afterDelay:0.0f];
    }
    return self;
}

#pragma mark - Public Instance Methods (Configuration)

- (void)configureWithIdentifier:(NSString *)appIdentifier {
    _appIdentifier = [appIdentifier copy];
    
    [self initializeModules];
    
    [self applyConfig:[[PRESConfigManager sharedInstance] getConfigWithAppKey:appIdentifier]];
}

- (void)configureWithIdentifier:(NSString *)appIdentifier delegate:(id)delegate {
    _delegate = delegate;
    _appIdentifier = [appIdentifier copy];
    
    [self initializeModules];
    
    [self applyConfig:[[PRESConfigManager sharedInstance] getConfigWithAppKey:appIdentifier]];
}

- (void)configureWithBetaIdentifier:(NSString *)betaIdentifier liveIdentifier:(NSString *)liveIdentifier delegate:(id)delegate {
    _delegate = delegate;
    
    // check the live identifier now, because otherwise invalid identifier would only be logged when the app is already in the store
    if (![self checkValidityOfAppIdentifier:liveIdentifier]) {
        [self logInvalidIdentifier:@"liveIdentifier"];
        _liveIdentifier = [liveIdentifier copy];
    }
    
    if ([self shouldUseLiveIdentifier]) {
        _appIdentifier = [liveIdentifier copy];
    }
    else {
        _appIdentifier = [betaIdentifier copy];
    }
    
    [self initializeModules];
    
    [self applyConfig:[[PRESConfigManager sharedInstance] getConfigWithAppKey:_appIdentifier]];
}


- (void)startManager {
    if (!_validAppIdentifier) return;
    if (_startManagerIsInvoked) {
        PRESLogWarning(@"[PreSniffObjc] Warning: startManager should only be invoked once! This call is ignored.");
        return;
    }
    
    // Fix bug where Application Support directory was encluded from backup
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    pres_fixBackupAttributeForURL(appSupportURL);
    
    if (![self isSetUpOnMainThread]) return;
    
    if ((self.appEnvironment == PRESEnvironmentAppStore) && [self isInstallTrackingDisabled]) {
        _installString = pres_appAnonID(YES);
    }
    
    PRESLogDebug(@"INFO: Starting PRESManager");
    _startManagerIsInvoked = YES;
    
    // start CrashManager
    if (![self isCrashManagerDisabled]) {
        PRESLogDebug(@"INFO: Start CrashManager");
        
        [_crashManager startManager];
    }
    
    // App Extensions can only use PRESCrashManager, so ignore all others automatically
    if (pres_isRunningInAppExtension()) {
        return;
    }
    
    // start MetricsManager
    if (!self.isMetricsManagerDisabled) {
        PRESLogDebug(@"INFO: Start MetricsManager");
        [_metricsManager startManager];
        [PRESCategoryContainer activateCategory];
    }
    if (!self.isHttpMonitorDisabled) {
        [PRESURLProtocol enableHTTPSniff];
    }
}

- (void)setDisableMetricsManager:(BOOL)disableMetricsManager {
    if (_metricsManager) {
        _metricsManager.disabled = disableMetricsManager;
    }
    _disableMetricsManager = disableMetricsManager;
    
}

- (void)setDisableHttpMonitor:(BOOL)disableHttpMonitor {
    _disableHttpMonitor = disableHttpMonitor;
    if (disableHttpMonitor) {
        [PRESURLProtocol disableHTTPSniff];
    } else {
        [PRESURLProtocol enableHTTPSniff];
    }
}

- (void)setServerURL:(NSString *)aServerURL {
    // ensure url ends with a trailing slash
    if (![aServerURL hasSuffix:@"/"]) {
        aServerURL = [NSString stringWithFormat:@"%@/", aServerURL];
    }
    
    if (_serverURL != aServerURL) {
        _serverURL = [aServerURL copy];
        
        if (_hockeyAppClient) {
            _hockeyAppClient.baseURL = [NSURL URLWithString:_serverURL ?: PRESHOCKEYSDK_URL];
        }
    }
}


- (void)setDelegate:(id<PRESManagerDelegate>)delegate {
    if (self.appEnvironment != PRESEnvironmentAppStore) {
        if (_startManagerIsInvoked) {
            PRESLogError(@"[PreSniffObjc] ERROR: The `delegate` property has to be set before calling [[PRESManager sharedPRESManager] startManager] !");
        }
    }
    
    if (_delegate != delegate) {
        _delegate = delegate;
        
        if (_crashManager) {
            _crashManager.delegate = _delegate;
        }
    }
}

- (PRESLogLevel)logLevel {
    return PRESLogger.currentLogLevel;
}

- (void)setLogLevel:(PRESLogLevel)logLevel {
    PRESLogger.currentLogLevel = logLevel;
}

- (void)setLogHandler:(PRESLogHandler)logHandler {
    [PRESLogger setLogHandler:logHandler];
}

- (void)modifyKeychainUserValue:(NSString *)value forKey:(NSString *)key {
    NSError *error = nil;
    BOOL success = YES;
    NSString *updateType = @"update";
    
    if (value) {
        success = [PRESKeychainUtils storeUsername:key
                                       andPassword:value
                                    forServiceName:pres_keychainPreSniffObjcServiceName()
                                    updateExisting:YES
                                     accessibility:kSecAttrAccessibleAlwaysThisDeviceOnly
                                             error:&error];
    } else {
        updateType = @"delete";
        if ([PRESKeychainUtils getPasswordForUsername:key
                                       andServiceName:pres_keychainPreSniffObjcServiceName()
                                                error:&error]) {
            success = [PRESKeychainUtils deleteItemForUsername:key
                                                andServiceName:pres_keychainPreSniffObjcServiceName()
                                                         error:&error];
        }
    }
    
    if (!success) {
        NSString *errorDescription = [error description] ?: @"";
        PRESLogError(@"ERROR: Couldn't %@ key %@ in the keychain. %@", updateType, key, errorDescription);
    }
}

- (void)setUserID:(NSString *)userID {
    // always set it, since nil value will trigger removal of the keychain entry
    _userID = userID;
    
    [self modifyKeychainUserValue:userID forKey:kPRESMetaUserID];
}

- (void)setUserName:(NSString *)userName {
    // always set it, since nil value will trigger removal of the keychain entry
    _userName = userName;
    
    [self modifyKeychainUserValue:userName forKey:kPRESMetaUserName];
}

- (void)setUserEmail:(NSString *)userEmail {
    // always set it, since nil value will trigger removal of the keychain entry
    _userEmail = userEmail;
    
    [self modifyKeychainUserValue:userEmail forKey:kPRESMetaUserEmail];
}

- (void)testIdentifier {
    if (!_appIdentifier || (self.appEnvironment == PRESEnvironmentAppStore)) {
        return;
    }
    
    NSDate *now = [NSDate date];
    NSString *timeString = [NSString stringWithFormat:@"%.0f", [now timeIntervalSince1970]];
    [self pingServerForIntegrationStartWorkflowWithTimeString:timeString appIdentifier:_appIdentifier];
    
    if (_liveIdentifier) {
        [self pingServerForIntegrationStartWorkflowWithTimeString:timeString appIdentifier:_liveIdentifier];
    }
}


- (NSString *)version {
    return [PRESVersion getSDKVersion];
}

- (NSString *)build {
    return [PRESVersion getSDKBuild];
}

#pragma mark - Private Instance Methods

- (PRESNetworkClient *)hockeyAppClient {
    if (!_hockeyAppClient) {
        _hockeyAppClient = [[PRESNetworkClient alloc] initWithBaseURL:[NSURL URLWithString:self.serverURL]];
    }
    return _hockeyAppClient;
}

- (NSString *)integrationFlowTimeString {
    NSString *timeString = [[NSBundle mainBundle] objectForInfoDictionaryKey:PRESHOCKEY_INTEGRATIONFLOW_TIMESTAMP];
    
    return timeString;
}

- (BOOL)integrationFlowStartedWithTimeString:(NSString *)timeString {
    if (timeString == nil || (self.appEnvironment == PRESEnvironmentAppStore)) {
        return NO;
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [dateFormatter setLocale:enUSPOSIXLocale];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *integrationFlowStartDate = [dateFormatter dateFromString:timeString];
    
    if (integrationFlowStartDate && [integrationFlowStartDate timeIntervalSince1970] > [[NSDate date] timeIntervalSince1970] - (60 * 10) ) {
        return YES;
    }
    
    return NO;
}

- (void)pingServerForIntegrationStartWorkflowWithTimeString:(NSString *)timeString appIdentifier:(NSString *)appIdentifier {
    if (!appIdentifier || (self.appEnvironment == PRESEnvironmentAppStore)) {
        return;
    }
    
    NSString *integrationPath = [NSString stringWithFormat:@"api/3/apps/%@/integration", pres_encodeAppIdentifier(appIdentifier)];
    
    PRESLogDebug(@"INFO: Sending integration workflow ping to %@", integrationPath);
    
    NSDictionary *params = @{@"timestamp": timeString,
                             @"sdk": PRESHOCKEY_NAME,
                             @"sdk_version": [PRESVersion getSDKVersion],
                             @"bundle_version": [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"]
                             };
    
    if ([PRESHelper isURLSessionSupported]) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        __block NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        NSURLRequest *request = [[self hockeyAppClient] requestWithMethod:@"POST" path:integrationPath parameters:params];
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request
                                                completionHandler: ^(NSData *data, NSURLResponse *response, NSError *error) {
                                                    [session finishTasksAndInvalidate];
                                                    
                                                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
                                                    [self logPingMessageForStatusCode:httpResponse.statusCode];
                                                }];
        [task resume];
    }else{
        [[self hockeyAppClient] postPath:integrationPath
                              parameters:params
                              completion:^(PRESHTTPOperation *operation, NSData* responseData, NSError *error) {
                                  [self logPingMessageForStatusCode:operation.response.statusCode];
                              }];
    }
    
}

- (void)logPingMessageForStatusCode:(NSInteger)statusCode {
    switch (statusCode) {
        case 400:
            PRESLogError(@"ERROR: App ID not found");
            break;
        case 201:
            PRESLogDebug(@"INFO: Ping accepted.");
            break;
        case 200:
            PRESLogDebug(@"INFO: Ping accepted. Server already knows.");
            break;
        default:
            PRESLogError(@"ERROR: Unknown error");
            break;
    }
}

- (void)validateStartManagerIsInvoked {
    if (_validAppIdentifier && (self.appEnvironment != PRESEnvironmentAppStore)) {
        if (!_startManagerIsInvoked) {
            PRESLogError(@"[PreSniffObjc] ERROR: You did not call [[PRESManager sharedPRESManager] startManager] to startup the PreSniffObjc! Please do so after setting up all properties. The SDK is NOT running.");
        }
    }
}

- (BOOL)isSetUpOnMainThread {
    NSString *errorString = @"ERROR: PreSniffObjc has to be setup on the main thread!";
    
    if (!NSThread.isMainThread) {
        if (self.appEnvironment == PRESEnvironmentAppStore) {
            PRESLogError(@"%@", errorString);
        } else {
            PRESLogError(@"%@", errorString);
            NSAssert(NSThread.isMainThread, errorString);
        }
        
        return NO;
    }
    
    return YES;
}

- (BOOL)shouldUseLiveIdentifier {
    BOOL delegateResult = NO;
    if ([_delegate respondsToSelector:@selector(shouldUseLiveIdentifierForPRESManager:)]) {
        delegateResult = [(NSObject <PRESManagerDelegate>*)_delegate shouldUseLiveIdentifierForPRESManager:self];
    }
    
    return (delegateResult) || (_appEnvironment == PRESEnvironmentAppStore);
}

- (void)initializeModules {
    if (_managersInitialized) {
        PRESLogWarning(@"[PreSniffObjc] Warning: The SDK should only be initialized once! This call is ignored.");
        return;
    }
    
    _validAppIdentifier = [self checkValidityOfAppIdentifier:_appIdentifier];
    
    if (![self isSetUpOnMainThread]) return;
    
    _startManagerIsInvoked = NO;
    
    if (_validAppIdentifier) {
        PRESLogDebug(@"INFO: Setup CrashManager");
        _crashManager = [[PRESCrashManager alloc] initWithAppIdentifier:_appIdentifier
                                                         appEnvironment:_appEnvironment
                                                        hockeyAppClient:[self hockeyAppClient]];
        _crashManager.delegate = _delegate;
        
        
        PRESLogDebug(@"INFO: Setup MetricsManager");
        NSString *iKey = pres_appIdentifierToGuid(_appIdentifier);
        _metricsManager = [[PRESMetricsManager alloc] initWithAppIdentifier:iKey appEnvironment:_appEnvironment];
        
        if (self.appEnvironment != PRESEnvironmentAppStore) {
            NSString *integrationFlowTime = [self integrationFlowTimeString];
            if (integrationFlowTime && [self integrationFlowStartedWithTimeString:integrationFlowTime]) {
                [self pingServerForIntegrationStartWorkflowWithTimeString:integrationFlowTime appIdentifier:_appIdentifier];
            }
        }
        _managersInitialized = YES;
    } else {
        [self logInvalidIdentifier:@"app identifier"];
    }
}

- (void)applyConfig:(PRESConfig *)config {
    self.disableCrashManager = !config.crashReportEnabled;
    self.disableMetricsManager = !config.telemetryEnabled;
    self.disableHttpMonitor = !config.httpMonitorEnabled;
}

- (void)diagnose:(NSString *)host
        complete:(PRESNetDiagCompleteHandler)complete {
    [PRESNetDiag diagnose:host appKey:_appIdentifier complete:complete];
}

@end
