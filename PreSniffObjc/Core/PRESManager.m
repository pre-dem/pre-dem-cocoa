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
#import "PRESConfigManager.h"
#import "PRESNetDiag.h"
#import "PRESCrashManagerPrivate.h"
#import "PRESMetricsManagerPrivate.h"
#import "PRESURLProtocol.h"

@interface PRESManager ()
<
PRESConfigManagerDelegate
>

@end


@implementation PRESManager {
    NSString *_appIdentifier;
    NSString *_liveIdentifier;
    
    BOOL _validAppIdentifier;
    
    BOOL _startManagerIsInvoked;
    
    BOOL _managersInitialized;
    
    PRESNetworkClient *_hockeyAppClient;
    
    PRESConfigManager *_configManager;
}


#pragma mark - Public Class Methods

+ (PRESManager *)sharedPRESManager {
    static PRESManager *sharedInstance = nil;
    static dispatch_once_t pred;
    
    dispatch_once(&pred, ^{
        sharedInstance = [[PRESManager alloc] init];
    });
    
    return sharedInstance;
}

- (instancetype)init {
    if ((self = [super init])) {
        _serverURL = PRES_URL;
        _delegate = nil;
        _managersInitialized = NO;
        
        _hockeyAppClient = nil;
        
        _disableCrashManager = NO;
        _disableMetricsManager = NO;
        
        _appEnvironment = pres_currentAppEnvironment();
        _startManagerIsInvoked = NO;
        
        _liveIdentifier = nil;
        _installString = pres_appAnonID(NO);
        
        _configManager = [PRESConfigManager sharedInstance];
        _configManager.delegate = self;
        
        [self performSelector:@selector(validateStartManagerIsInvoked) withObject:nil afterDelay:0.0f];
    }
    return self;
}

#pragma mark - Public Instance Methods (Configuration)

- (void)configureWithIdentifier:(NSString *)appIdentifier {
    _appIdentifier = [appIdentifier copy];
    
    [self initializeModules];
    
    [self applyConfig:[_configManager getConfigWithAppKey:appIdentifier]];
}

- (void)configureWithIdentifier:(NSString *)appIdentifier delegate:(id)delegate {
    _delegate = delegate;
    _appIdentifier = [appIdentifier copy];
    
    [self initializeModules];
    
    [self applyConfig:[_configManager getConfigWithAppKey:appIdentifier]];
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
    
    [self applyConfig:[_configManager getConfigWithAppKey:_appIdentifier]];
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
            _hockeyAppClient.baseURL = [NSURL URLWithString:_serverURL ?: PRES_URL];
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
        _metricsManager = [[PRESMetricsManager alloc] initWithAppIdentifier:_appIdentifier appEnvironment:_appEnvironment];
        
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

- (void)configManager:(PRESConfigManager *)manager didReceivedConfig:(PRESConfig *)config {
    [self applyConfig:config];
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

@end
