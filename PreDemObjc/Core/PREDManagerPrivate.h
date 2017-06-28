//
//  PREDManagerPrivate.h
//  Pods
//
//  Created by Troy on 2017/6/27.
//
//

#ifndef PREDManagerPrivate_h
#define PREDManagerPrivate_h

#import <UIKit/UIKit.h>

#import "PREDManager.h"
#import "PREDConfigManager.h"

@interface PREDManager ()
<
PREDConfigManagerDelegate
>

///-----------------------------------------------------------------------------
/// @name Environment
///-----------------------------------------------------------------------------

/**
 Enum that indicates what kind of environment the application is installed and running in.
 
 This property can be used to disable or enable specific funtionality
 only when specific conditions are met.
 That could mean for example, to only enable debug UI elements
 when the app has been installed over PreDem but not in the AppStore.
 
 The underlying enum type at the moment only specifies values for the AppStore,
 TestFlight and Other. Other summarizes several different distribution methods
 and we might define additional specifc values for other environments in the future.
 
 @see PREDEnvironment
 */
@property (nonatomic, readonly) PREDEnvironment appEnvironment;


/**
 Returns the app installation specific anonymous UUID
 
 The value returned by this method is unique and persisted per app installation
 in the keychain.  It is also being used in crash reports as `CrashReporter Key`
 and internally when sending crash reports and feedback messages.
 
 This is not identical to the `[ASIdentifierManager advertisingIdentifier]` or
 the `[UIDevice identifierForVendor]`!
 */
@property (nonatomic, readonly) NSString * _Nullable installString;

/**
 Set the delegate
 
 Defines the class that implements the optional protocol `PREDManagerDelegate`.
 
 The delegate will automatically be propagated to all components. There is no need to set the delegate
 for each component individually.
 
 @warning This property needs to be set before calling `startManager`
 
 @see PREDManagerDelegate
 @see PREDCrashManagerDelegate
 */
@property (nonatomic, weak, nullable) id<PREDManagerDelegate> delegate;

/**
 Defines the server URL to send data to or request data from
 
 By default this is set to the PreDem servers and there rarely should be a
 need to modify that.
 Please be aware that the URL for `PREDMetricsManager` needs to be set separately
 as this class uses a different endpoint!
 
 @warning This property needs to be set before calling `startManager`
 */
@property (nonatomic, strong) NSString * _Nullable serverURL;

///-----------------------------------------------------------------------------
/// @name Modules
///-----------------------------------------------------------------------------

/**
 Reference to the initialized PREDCrashManager module
 
 Returns the PREDCrashManager instance initialized by PREDManager
 
 @see configureWithIdentifier:delegate:
 @see configureWithBetaIdentifier:liveIdentifier:delegate:
 @see startManager
 @see disableCrashManager
 */
@property (nonatomic, strong, readonly) PREDCrashManager * _Nullable crashManager;


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
 Flag the determines whether the PREDMetricsManager should be disabled
 
 If this flag is enabled, then sending metrics data such as sessions and users
 will be turned off!
 
 Please note that the PREDMetricsManager instance will be initialized anyway!
 
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

/**
 Set a custom block that handles all the log messages that are emitted from the SDK.
 
 You can use this to reroute the messages that would normally be logged by `NSLog();`
 to your own custom logging framework.
 
 An example of how to do this with NSLogger:
 
 ```
 [[PREDManager sharedPREDManager] setLogHandler:^(PREDLogMessageProvider messageProvider, PREDLogLevel logLevel, const char *file, const char *function, uint line) {
 LogMessageRawF(file, (int)line, function, @"PreDemObjc", (int)logLevel-1, messageProvider());
 }];
 ```
 
 or with CocoaLumberjack:
 
 ```
 [[PREDManager sharedPREDManager] setLogHandler:^(PREDLogMessageProvider messageProvider, PREDLogLevel logLevel, const char *file, const char *function, uint line) {
 [DDLog log:YES message:messageProvider() level:ddLogLevel flag:(DDLogFlag)(1 << (logLevel-1)) context:CocoaLumberjackContext file:file function:function line:line tag:nil];
 }];
 ```
 
 @param logHandler The block of type PREDLogHandler that will process all logged messages.
 */
+ (void)setLogHandler:(PREDLogHandler _Nullable )logHandler;

/**
 Initializes the manager with a particular app identifier
 
 Initialize the manager with a PreDem app identifier.
 
 [[PREDManager sharedPREDManager]
 startWithAppKey:@"<AppIdentifierFromPreDem>"
 serviceDomain:@"<ServiceDomain>"];
 
 @param appKey The app key that should be used.
 @param serviceDomain The service domain that data will be reported to or requested from.
 */
- (void)startWithAppKey:(NSString *_Nonnull)appKey serviceDomain:(NSString *_Nonnull)serviceDomain;

/**
 *  diagnose current network environment
 *
 *  @param host     the end point you want this diagnose action perform with
 *  @param complete diagnose result can be retrieved from the block
 */
- (void)diagnose:(NSString *_Nonnull)host
        complete:(PREDNetDiagCompleteHandler _Nonnull )complete;

/**
 Reference to the initialized PREDMetricsManager module
 
 Returns the PREDMetricsManager instance initialized by PREDManager
 */
@property (nonatomic, strong, readonly) PREDMetricsManager * _Nonnull metricsManager;

+(PREDManager *_Nonnull)sharedPREDManager;

@end

//extern PREDConfigManager* _Nonnull g_pred_sharedmanager();

#endif /* PREDManagerPrivate_h */
