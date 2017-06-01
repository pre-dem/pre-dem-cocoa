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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PRESNullability.h"
#import "PRESEnums.h"

@protocol PRESManagerDelegate;

@class PRESBaseManager;
@class PRESCrashManager;
@class PRESMetricsManager;
@class PRESNetDiagResult;

NS_ASSUME_NONNULL_BEGIN

typedef void (^PRESNetDiagCompleteHandler)(PRESNetDiagResult* result);

@interface PRESManager: NSObject

#pragma mark - Public Methods

///-----------------------------------------------------------------------------
/// @name Initialization
///-----------------------------------------------------------------------------

/**
 Returns a shared PRESManager object
 
 @return A singleton PRESManager instance ready use
 */
+ (PRESManager *)sharedPRESManager;


/**
 Initializes the manager with a particular app identifier
 
 Initialize the manager with a HockeyApp app identifier.
 
 [[PRESManager sharedPRESManager]
 configureWithIdentifier:@"<AppIdentifierFromHockeyApp>"];
 
 @see configureWithIdentifier:delegate:
 @see configureWithBetaIdentifier:liveIdentifier:delegate:
 @see startManager
 @param appIdentifier The app identifier that should be used.
 */
- (void)configureWithIdentifier:(NSString *)appIdentifier;


/**
 Initializes the manager with a particular app identifier and delegate
 
 Initialize the manager with a HockeyApp app identifier and assign the class that
 implements the optional protocols `PRESManagerDelegate`, `PRESCrashManagerDelegate` or
 `PRESUpdateManagerDelegate`.
 
 [[PRESManager sharedPRESManager]
 configureWithIdentifier:@"<AppIdentifierFromHockeyApp>"
 delegate:nil];
 
 @see configureWithIdentifier:
 @see configureWithBetaIdentifier:liveIdentifier:delegate:
 @see startManager
 @see PRESManagerDelegate
 @see PRESCrashManagerDelegate
 @see PRESUpdateManagerDelegate
 @see PRESFeedbackManagerDelegate
 @param appIdentifier The app identifier that should be used.
 @param delegate `nil` or the class implementing the option protocols
 */
- (void)configureWithIdentifier:(NSString *)appIdentifier delegate:(nullable id<PRESManagerDelegate>)delegate;


/**
 Initializes the manager with an app identifier for beta, one for live usage and delegate
 
 Initialize the manager with different HockeyApp app identifiers for beta and live usage.
 All modules will automatically detect if the app is running in the App Store and use
 the live app identifier for that. In all other cases it will use the beta app identifier.
 And also assign the class that implements the optional protocols `PRESManagerDelegate`,
 `PRESCrashManagerDelegate` or `PRESUpdateManagerDelegate`
 
 [[PRESManager sharedPRESManager]
 configureWithBetaIdentifier:@"<AppIdentifierForBetaAppFromHockeyApp>"
 liveIdentifier:@"<AppIdentifierForLiveAppFromHockeyApp>"
 delegate:nil];
 
 We recommend using one app entry on HockeyApp for your beta versions and another one for
 your live versions. The reason is that you will have way more beta versions than live
 versions, but on the other side get way more crash reports on the live version. Separating
 them into two different app entries makes it easier to work with the data. In addition
 you will likely end up having the same version number for a beta and live version which
 would mix different data into the same version. Also the live version does not require
 you to upload any IPA files, uploading only the dSYM package for crash reporting is
 just fine.
 
 @see configureWithIdentifier:
 @see configureWithIdentifier:delegate:
 @see startManager
 @see PRESManagerDelegate
 @see PRESCrashManagerDelegate
 @see PRESUpdateManagerDelegate
 @see PRESFeedbackManagerDelegate
 @param betaIdentifier The app identifier for the _non_ app store (beta) configurations
 @param liveIdentifier The app identifier for the app store configurations.
 @param delegate `nil` or the class implementing the optional protocols
 */
- (void)configureWithBetaIdentifier:(NSString *)betaIdentifier liveIdentifier:(NSString *)liveIdentifier delegate:(nullable id<PRESManagerDelegate>)delegate;


/**
 Starts the manager and runs all modules
 
 Call this after configuring the manager and setting up all modules.
 
 @see configureWithIdentifier:delegate:
 @see configureWithBetaIdentifier:liveIdentifier:delegate:
 */
- (void)startManager;


#pragma mark - Public Properties

///-----------------------------------------------------------------------------
/// @name Modules
///-----------------------------------------------------------------------------


/**
 Set the delegate
 
 Defines the class that implements the optional protocol `PRESManagerDelegate`.
 
 The delegate will automatically be propagated to all components. There is no need to set the delegate
 for each component individually.
 
 @warning This property needs to be set before calling `startManager`
 
 @see PRESManagerDelegate
 @see PRESCrashManagerDelegate
 @see PRESUpdateManagerDelegate
 @see PRESFeedbackManagerDelegate
 */
@property (nonatomic, weak, nullable) id<PRESManagerDelegate> delegate;


/**
 Defines the server URL to send data to or request data from
 
 By default this is set to the HockeyApp servers and there rarely should be a
 need to modify that.
 Please be aware that the URL for `PRESMetricsManager` needs to be set separately
 as this class uses a different endpoint!
 
 @warning This property needs to be set before calling `startManager`
 */
@property (nonatomic, strong) NSString *serverURL;

/**
 Reference to the initialized PRESCrashManager module
 
 Returns the PRESCrashManager instance initialized by PRESManager
 
 @see configureWithIdentifier:delegate:
 @see configureWithBetaIdentifier:liveIdentifier:delegate:
 @see startManager
 @see disableCrashManager
 */
@property (nonatomic, strong, readonly) PRESCrashManager *crashManager;


/**
 Flag the determines whether the Crash Manager should be disabled
 
 If this flag is enabled, then crash reporting is disabled and no crashes will
 be send.
 
 Please note that the Crash Manager instance will be initialized anyway, but crash report
 handling (signal and uncaught exception handlers) will **not** be registered.
 
 @warning This property needs to be set before calling `startManager`
 
 *Default*: _NO_
 @see crashManager
 */
@property (nonatomic, getter = isCrashManagerDisabled) BOOL disableCrashManager;

/**
 Reference to the initialized PRESMetricsManager module
 
 Returns the PRESMetricsManager instance initialized by PRESManager
 */
@property (nonatomic, strong, readonly) PRESMetricsManager *metricsManager;

/**
 Flag the determines whether the PRESMetricsManager should be disabled
 
 If this flag is enabled, then sending metrics data such as sessions and users
 will be turned off!
 
 Please note that the PRESMetricsManager instance will be initialized anyway!
 
 *Default*: _NO_
 @see metricsManager
 */
@property (nonatomic, getter = isMetricsManagerDisabled) BOOL disableMetricsManager;

/**
 Flag the determines whether the HttpMonitor should be disabled
 
 If this flag is enabled, then sending HttpMonitor data
 will be turned off!
 
 *Default*: _NO_
 */
@property (nonatomic, getter = isHttpMonitorDisabled) BOOL disableHttpMonitor;

///-----------------------------------------------------------------------------
/// @name Environment
///-----------------------------------------------------------------------------


/**
 Enum that indicates what kind of environment the application is installed and running in.
 
 This property can be used to disable or enable specific funtionality
 only when specific conditions are met.
 That could mean for example, to only enable debug UI elements
 when the app has been installed over HockeyApp but not in the AppStore.
 
 The underlying enum type at the moment only specifies values for the AppStore,
 TestFlight and Other. Other summarizes several different distribution methods
 and we might define additional specifc values for other environments in the future.
 
 @see PRESEnvironment
 */
@property (nonatomic, readonly) PRESEnvironment appEnvironment;


/**
 Returns the app installation specific anonymous UUID
 
 The value returned by this method is unique and persisted per app installation
 in the keychain.  It is also being used in crash reports as `CrashReporter Key`
 and internally when sending crash reports and feedback messages.
 
 This is not identical to the `[ASIdentifierManager advertisingIdentifier]` or
 the `[UIDevice identifierForVendor]`!
 */
@property (nonatomic, readonly) NSString *installString;


/**
 Disable tracking the installation of an app on a device
 
 This will cause the app to generate a new `installString` value every time the
 app is cold started.
 
 This property is only considered in App Store Environment, since it would otherwise
 affect the `PRESUpdateManager` and `PRESAuthenticator` functionalities!
 
 @warning This property needs to be set before calling `startManager`
 
 *Default*: _NO_
 */
@property (nonatomic, getter=isInstallTrackingDisabled) BOOL disableInstallTracking;

///-----------------------------------------------------------------------------
/// @name Debug Logging
///-----------------------------------------------------------------------------

/**
 This property is used indicate the amount of verboseness and severity for which
 you want to see log messages in the console.
 */
@property (nonatomic, assign) PRESLogLevel logLevel;

/**
 Set a custom block that handles all the log messages that are emitted from the SDK.
 
 You can use this to reroute the messages that would normally be logged by `NSLog();`
 to your own custom logging framework.
 
 An example of how to do this with NSLogger:
 
 ```
 [[PRESManager sharedPRESManager] setLogHandler:^(PRESLogMessageProvider messageProvider, PRESLogLevel logLevel, const char *file, const char *function, uint line) {
 LogMessageRawF(file, (int)line, function, @"PreSniffObjc", (int)logLevel-1, messageProvider());
 }];
 ```
 
 or with CocoaLumberjack:
 
 ```
 [[PRESManager sharedPRESManager] setLogHandler:^(PRESLogMessageProvider messageProvider, PRESLogLevel logLevel, const char *file, const char *function, uint line) {
 [DDLog log:YES message:messageProvider() level:ddLogLevel flag:(DDLogFlag)(1 << (logLevel-1)) context:CocoaLumberjackContext file:file function:function line:line tag:nil];
 }];
 ```
 
 @param logHandler The block of type PRESLogHandler that will process all logged messages.
 */
- (void)setLogHandler:(PRESLogHandler)logHandler;


///-----------------------------------------------------------------------------
/// @name Integration test
///-----------------------------------------------------------------------------

/**
 Pings the server with the HockeyApp app identifiers used for initialization
 
 Call this method once for debugging purposes to test if your SDK setup code
 reaches the server successfully.
 
 Once invoked, check the apps page on HockeyApp for a verification.
 
 If you setup the SDK with a beta and live identifier, a call to both app IDs will be done.
 
 This call is ignored if the app is running in the App Store!.
 */
- (void)testIdentifier;

- (void)diagnose:(NSString *)host
        complete:(PRESNetDiagCompleteHandler)complete;


///-----------------------------------------------------------------------------
/// @name Additional meta data
///-----------------------------------------------------------------------------

/** Set the userid that should used in the SDK components
 
 Right now this is used by the `PRESCrashManager` to attach to a crash report.
 `PRESFeedbackManager` uses it too for assigning the user to a discussion thread.
 
 The value can be set at any time and will be stored in the keychain on the current
 device only! To delete the value from the keychain set the value to `nil`.
 
 This property is optional and can be used as an alternative to the delegate. If you
 want to define specific data for each component, use the delegate instead which does
 overwrite the values set by this property.
 
 @warning When returning a non nil value, crash reports are not anonymous any more
 and the crash alerts will not show the word "anonymous"!
 
 @warning This property needs to be set before calling `startManager` to be considered
 for being added to crash reports as meta data.
 
 @see userName
 @see userEmail
 @see `[PRESManagerDelegate userIDForHockeyManager:componentManager:]`
 */
@property (nonatomic, copy, nullable) NSString *userID;


/** Set the user name that should used in the SDK components
 
 Right now this is used by the `PRESCrashManager` to attach to a crash report.
 `PRESFeedbackManager` uses it too for assigning the user to a discussion thread.
 
 The value can be set at any time and will be stored in the keychain on the current
 device only! To delete the value from the keychain set the value to `nil`.
 
 This property is optional and can be used as an alternative to the delegate. If you
 want to define specific data for each component, use the delegate instead which does
 overwrite the values set by this property.
 
 @warning When returning a non nil value, crash reports are not anonymous any more
 and the crash alerts will not show the word "anonymous"!
 
 @warning This property needs to be set before calling `startManager` to be considered
 for being added to crash reports as meta data.
 
 @see userID
 @see userEmail
 @see `[PRESManagerDelegate userNameForHockeyManager:componentManager:]`
 */
@property (nonatomic, copy, nullable) NSString *userName;


/** Set the users email address that should used in the SDK components
 
 Right now this is used by the `PRESCrashManager` to attach to a crash report.
 `PRESFeedbackManager` uses it too for assigning the user to a discussion thread.
 
 The value can be set at any time and will be stored in the keychain on the current
 device only! To delete the value from the keychain set the value to `nil`.
 
 This property is optional and can be used as an alternative to the delegate. If you
 want to define specific data for each component, use the delegate instead which does
 overwrite the values set by this property.
 
 @warning When returning a non nil value, crash reports are not anonymous any more
 and the crash alerts will not show the word "anonymous"!
 
 @warning This property needs to be set before calling `startManager` to be considered
 for being added to crash reports as meta data.
 
 @see userID
 @see userName
 @see [PRESManagerDelegate userEmailForHockeyManager:componentManager:]
 */
@property (nonatomic, copy, nullable) NSString *userEmail;


///-----------------------------------------------------------------------------
/// @name SDK meta data
///-----------------------------------------------------------------------------

/**
 Returns the SDK Version (CFBundleShortVersionString).
 */
- (NSString *)version;

/**
 Returns the SDK Build (CFBundleVersion) as a string.
 */
- (NSString *)build;

@end

NS_ASSUME_NONNULL_END
