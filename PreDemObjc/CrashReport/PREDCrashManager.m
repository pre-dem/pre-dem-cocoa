//
//  PREDCrashManager.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import "PREDemObjc.h"
#import "PREDPrivate.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import "PREDManagerPrivate.h"
#import "PREDCrashManager.h"
#import "PREDCrashReportTextFormatter.h"
#import "PREDCrashCXXExceptionHandler.h"
#import "PREDVersion.h"
#include <sys/sysctl.h>

// internal keys

static NSString *const kPREDAppWentIntoBackgroundSafely = @"PREDAppWentIntoBackgroundSafely";
static NSString *const kPREDAppDidReceiveLowMemoryNotification = @"PREDAppDidReceiveLowMemoryNotification";
static NSString *const kPREDFakeCrashReport = @"PREDFakeCrashAppString";
static NSString *const kPREDCrashKillSignal = @"SIGKILL";

// Temporary class until PLCR catches up
// We trick PLCR with an Objective-C exception.
//
// This code provides us access to the C++ exception message, including a correct stack trace.
//
@interface PREDCrashCXXExceptionWrapperException : NSException

- (instancetype)initWithCXXExceptionInfo:(const PREDCrashUncaughtCXXExceptionInfo *)info;

@end

@implementation PREDCrashCXXExceptionWrapperException {
    const PREDCrashUncaughtCXXExceptionInfo *_info;
}

- (instancetype)initWithCXXExceptionInfo:(const PREDCrashUncaughtCXXExceptionInfo *)info {
    extern char* __cxa_demangle(const char* mangled_name, char* output_buffer, size_t* length, int* status);
    char *demangled_name = &__cxa_demangle ? __cxa_demangle(info->exception_type_name ?: "", NULL, NULL, NULL) : NULL;
    
    if ((self = [super
                 initWithName:[NSString stringWithUTF8String:demangled_name ?: info->exception_type_name ?: ""]
                 reason:[NSString stringWithUTF8String:info->exception_message ?: ""]
                 userInfo:nil])) {
        _info = info;
    }
    return self;
}

- (NSArray *)callStackReturnAddresses {
    NSMutableArray *cxxFrames = [NSMutableArray arrayWithCapacity:_info->exception_frames_count];
    
    for (uint32_t i = 0; i < _info->exception_frames_count; ++i) {
        [cxxFrames addObject:[NSNumber numberWithUnsignedLongLong:_info->exception_frames[i]]];
    }
    return cxxFrames;
}

@end


// C++ Exception Handler
static void uncaught_cxx_exception_handler(const PREDCrashUncaughtCXXExceptionInfo *info) {
    // This relies on a LOT of sneaky internal knowledge of how PLCR works and should not be considered a long-term solution.
    NSGetUncaughtExceptionHandler()([[PREDCrashCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
    abort();
}


@implementation PREDCrashManager {
    NSMutableArray *_crashFiles;
    NSFileManager  *_fileManager;
    
    BOOL _sendingInProgress;
    BOOL _isSetup;
    
    BOOL _didLogLowMemoryWarning;
    
    id _appDidBecomeActiveObserver;
    id _appWillTerminateObserver;
    id _appDidEnterBackgroundObserver;
    id _appWillEnterForegroundObserver;
    id _appDidReceiveLowMemoryWarningObserver;
    id _networkDidBecomeReachableObserver;
}

- (instancetype)initWithAppIdentifier:(NSString *)appIdentifier networkClient:(PREDNetworkClient *)networkClient {
    if ((self = [super init])) {
        _isSetup = NO;
        _networkClient = networkClient;
        _plCrashReporter = nil;
        _exceptionHandler = nil;
        _didCrashInLastSession = NO;
        _didLogLowMemoryWarning = NO;
        _fileManager = [[NSFileManager alloc] init];
        _crashFiles = [[NSMutableArray alloc] init];
        _crashesDir = PREDHelper.settingsDir;
    }
    return self;
}

- (void) dealloc {
    [self unregisterObservers];
}

#pragma mark - Public

/**
 *	 Main startup sequence initializing PLCrashReporter if it wasn't disabled
 */
- (void)startManager {
    [self registerObservers];
    
    if (!_isSetup) {
        static dispatch_once_t plcrPredicate;
        dispatch_once(&plcrPredicate, ^{
            /* Configure our reporter */
            
            PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
            
            PLCrashReporterSymbolicationStrategy symbolicationStrategy = PLCrashReporterSymbolicationStrategyNone;
            if (self.isOnDeviceSymbolicationEnabled) {
                symbolicationStrategy = PLCrashReporterSymbolicationStrategyAll;
            }
            
            PREPLCrashReporterConfig *config = [[PREPLCrashReporterConfig alloc] initWithSignalHandlerType: signalHandlerType
                                                                                     symbolicationStrategy: symbolicationStrategy];
            self.plCrashReporter = [[PREPLCrashReporter alloc] initWithConfiguration: config];
            
            // Check if we previously crashed
            if ([self.plCrashReporter hasPendingCrashReport]) {
                _didCrashInLastSession = YES;
                [self handleCrashReport];
            }
            
            
            if (PREDHelper.isDebuggerAttached) {
                PREDLogWarning(@"Detecting crashes is NOT enabled due to running the app with a debugger attached.");
            } else {
                // Multiple exception handlers can be set, but we can only query the top level error handler (uncaught exception handler).
                //
                // To check if PLCrashReporter's error handler is successfully added, we compare the top
                // level one that is set before and the one after PLCrashReporter sets up its own.
                //
                // With delayed processing we can then check if another error handler was set up afterwards
                // and can show a debug warning log message, that the dev has to make sure the "newer" error handler
                // doesn't exit the process itself, because then all subsequent handlers would never be invoked.
                //
                // Note: ANY error handler setup BEFORE PreDemObjc initialization will not be processed!
                
                // get the current top level error handler
                NSUncaughtExceptionHandler *initialHandler = NSGetUncaughtExceptionHandler();
                
                // PLCrashReporter may only be initialized once. So make sure the developer
                // can't break this
                NSError *error = NULL;
                
                // Enable the Crash Reporter
                if (![self.plCrashReporter enableCrashReporterAndReturnError: &error]) {
                    PREDLogError(@"Could not enable crash reporter: %@", [error localizedDescription]);
                }
                
                // get the new current top level error handler, which should now be the one from PLCrashReporter
                NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
                
                // do we have a new top level error handler? then we were successful
                if (currentHandler && currentHandler != initialHandler) {
                    self.exceptionHandler = currentHandler;
                    
                    PREDLogDebug(@"Exception handler successfully initialized.");
                } else {
                    // this should never happen, theoretically only if NSSetUncaugtExceptionHandler() has some internal issues
                    PREDLogError(@"Exception handler could not be set. Make sure there is no other exception handler set up!");
                }
                
                // Add the C++ uncaught exception handler, which is currently not handled by PLCrashReporter internally
                [PREDCrashUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:uncaught_cxx_exception_handler];
            }
            _isSetup = YES;
        });
    }
    
    if ([[NSUserDefaults standardUserDefaults] valueForKey:kPREDAppDidReceiveLowMemoryNotification])
        _didReceiveMemoryWarningInLastSession = [[NSUserDefaults standardUserDefaults] boolForKey:kPREDAppDidReceiveLowMemoryNotification];
    
    if (!_didCrashInLastSession && self.isAppNotTerminatingCleanlyDetectionEnabled) {
        BOOL didAppSwitchToBackgroundSafely = YES;
        
        if ([[NSUserDefaults standardUserDefaults] valueForKey:kPREDAppWentIntoBackgroundSafely])
            didAppSwitchToBackgroundSafely = [[NSUserDefaults standardUserDefaults] boolForKey:kPREDAppWentIntoBackgroundSafely];
        
        if (!didAppSwitchToBackgroundSafely) {
            PREDLogVerbose(@"App kill detected, creating crash report.");
            [self createCrashReportForAppKill];
            _didCrashInLastSession = YES;
        }
    }
    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
        [self appEnteredForeground];
    }
    [self appEnteredForeground];
    
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPREDAppDidReceiveLowMemoryNotification];
    
    if(PREDHelper.isPreiOS8Environment) {
        // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self triggerDelayedProcessing];
    PREDLogVerbose(@"CrashManager startManager has finished.");
}

#pragma mark - Private


/**
 * Remove a cached crash report
 *
 *  @param filename The base filename of the crash report
 */
- (void)cleanCrashReportWithFilename:(NSString *)filename {
    if (!filename) return;
    
    NSError *error = NULL;
    
    [_fileManager removeItemAtPath:filename error:&error];
    [_crashFiles removeObject:filename];
}

- (void) registerObservers {
    __weak typeof(self) weakSelf = self;
    
    if(nil == _appDidBecomeActiveObserver) {
        _appDidBecomeActiveObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                        object:nil
                                                                                         queue:NSOperationQueue.mainQueue
                                                                                    usingBlock:^(NSNotification *note) {
                                                                                        typeof(self) strongSelf = weakSelf;
                                                                                        [strongSelf triggerDelayedProcessing];
                                                                                    }];
    }
    
    if(nil == _networkDidBecomeReachableObserver) {
        _networkDidBecomeReachableObserver = [[NSNotificationCenter defaultCenter] addObserverForName:PREDNetworkDidBecomeReachableNotification
                                                                                               object:nil
                                                                                                queue:NSOperationQueue.mainQueue
                                                                                           usingBlock:^(NSNotification *note) {
                                                                                               typeof(self) strongSelf = weakSelf;
                                                                                               [strongSelf triggerDelayedProcessing];
                                                                                           }];
    }
    
    if (nil ==  _appWillTerminateObserver) {
        _appWillTerminateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                                                      object:nil
                                                                                       queue:NSOperationQueue.mainQueue
                                                                                  usingBlock:^(NSNotification *note) {
                                                                                      typeof(self) strongSelf = weakSelf;
                                                                                      [strongSelf leavingAppSafely];
                                                                                  }];
    }
    
    if (nil ==  _appDidEnterBackgroundObserver) {
        _appDidEnterBackgroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                                                           object:nil
                                                                                            queue:NSOperationQueue.mainQueue
                                                                                       usingBlock:^(NSNotification *note) {
                                                                                           typeof(self) strongSelf = weakSelf;
                                                                                           [strongSelf leavingAppSafely];
                                                                                       }];
    }
    
    if (nil == _appWillEnterForegroundObserver) {
        _appWillEnterForegroundObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification
                                                                                            object:nil
                                                                                             queue:NSOperationQueue.mainQueue
                                                                                        usingBlock:^(NSNotification *note) {
                                                                                            typeof(self) strongSelf = weakSelf;
                                                                                            [strongSelf appEnteredForeground];
                                                                                        }];
    }
    
    if (nil == _appDidReceiveLowMemoryWarningObserver) {
        _appDidReceiveLowMemoryWarningObserver = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification
                                                                                                   object:nil
                                                                                                    queue:NSOperationQueue.mainQueue
                                                                                               usingBlock:^(NSNotification *note) {
                                                                                                   // we only need to log this once
                                                                                                   if (!_didLogLowMemoryWarning) {
                                                                                                       [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPREDAppDidReceiveLowMemoryNotification];
                                                                                                       _didLogLowMemoryWarning = YES;
                                                                                                       if(PREDHelper.isPreiOS8Environment) {
                                                                                                           // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
                                                                                                           [[NSUserDefaults standardUserDefaults] synchronize];
                                                                                                       }
                                                                                                   }
                                                                                               }];
    }
}

- (void) unregisterObservers {
    [self unregisterObserver:_appDidBecomeActiveObserver];
    [self unregisterObserver:_appWillTerminateObserver];
    [self unregisterObserver:_appDidEnterBackgroundObserver];
    [self unregisterObserver:_appWillEnterForegroundObserver];
    [self unregisterObserver:_appDidReceiveLowMemoryWarningObserver];
    
    [self unregisterObserver:_networkDidBecomeReachableObserver];
}

- (void) unregisterObserver:(id)observer {
    if (observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        observer = nil;
    }
}

- (void)leavingAppSafely {
    if (self.isAppNotTerminatingCleanlyDetectionEnabled) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPREDAppWentIntoBackgroundSafely];
        if(PREDHelper.isPreiOS8Environment) {
            // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
}

- (void)appEnteredForeground {
    // we disable kill detection while the debugger is running, since we'd get only false positives if the app is terminated by the user using the debugger
    if (PREDHelper.isDebuggerAttached) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPREDAppWentIntoBackgroundSafely];
    } else if (self.isAppNotTerminatingCleanlyDetectionEnabled) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPREDAppWentIntoBackgroundSafely];
        
        static dispatch_once_t predAppData;
        
        dispatch_once(&predAppData, ^{
            if(PREDHelper.isPreiOS8Environment) {
                // calling synchronize in pre-iOS 8 takes longer to sync than in iOS 8+, calling synchronize explicitly.
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        });
    }
}

#pragma mark - PLCrashReporter

/**
 *	 Process new crash reports provided by PLCrashReporter
 *
 */
- (void) handleCrashReport {
    PREDLogVerbose(@"VERBOSE: Handling crash report");
    NSError *error = NULL;
    
    if (!self.plCrashReporter) return;
    
    PREDLogVerbose(@"VERBOSE: AnalyzerInProgress file created");
    
    // Try loading the crash report
    NSData *crashData = [[NSData alloc] initWithData:[self.plCrashReporter loadPendingCrashReportDataAndReturnError: &error]];
    
    NSString *cacheFilename = [NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate]];
    
    if (crashData == nil) {
        PREDLogError(@"Could not load crash report: %@", error);
    } else {
        // get the startup timestamp from the crash report, and the file timestamp to calculate the timeinterval when the crash happened after startup
        PREPLCrashReport *report = [[PREPLCrashReport alloc] initWithData:crashData error:&error];
        
        if (report == nil) {
            PREDLogWarning(@"WARNING: Could not parse crash report");
        } else {
            NSDate *appStartTime = nil;
            NSDate *appCrashTime = nil;
            if ([report.processInfo respondsToSelector:@selector(processStartTime)]) {
                if (report.systemInfo.timestamp && report.processInfo.processStartTime) {
                    appStartTime = report.processInfo.processStartTime;
                    appCrashTime =report.systemInfo.timestamp;
                }
            }
            
            [crashData writeToFile:[_crashesDir stringByAppendingPathComponent: cacheFilename] atomically:YES];
            
            NSString *incidentIdentifier = @"???";
            if (report.uuidRef != NULL) {
                incidentIdentifier = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef));
            }
        }
    }
    [self.plCrashReporter purgePendingCrashReport];
}

/**
 *	Check if there are any new crash reports that are not yet processed
 *
 *	@return	`YES` if there is at least one new crash report found, `NO` otherwise
 */
- (BOOL)hasPendingCrashReport {
    if ([self.fileManager fileExistsAtPath:_crashesDir]) {
        NSError *error = NULL;
        
        NSArray *dirArray = [self.fileManager contentsOfDirectoryAtPath:_crashesDir error:&error];
        
        for (NSString *file in dirArray) {
            NSString *filePath = [_crashesDir stringByAppendingPathComponent:file];
            
            NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:filePath error:&error];
            if ([[fileAttributes objectForKey:NSFileType] isEqualToString:NSFileTypeRegular] &&
                [[fileAttributes objectForKey:NSFileSize] intValue] > 0 &&
                ![file hasSuffix:@".DS_Store"] &&
                ![file hasSuffix:@".plist"]) {
                [_crashFiles addObject:filePath];
            }
        }
    }
    
    if ([_crashFiles count] > 0) {
        PREDLogDebug(@"%lu pending crash reports found.", (unsigned long)[_crashFiles count]);
        return YES;
    } else {
        if (_didCrashInLastSession) {
            _didCrashInLastSession = NO;
        }
        
        return NO;
    }
}


#pragma mark - Crash Report Processing

- (void)triggerDelayedProcessing {
    PREDLogVerbose(@"VERBOSE: Triggering delayed crash processing.");
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(invokeDelayedProcessing) object:nil];
    [self performSelector:@selector(invokeDelayedProcessing) withObject:nil afterDelay:0.5];
}

/**
 * Delayed startup processing for everything that does not to be done in the app startup runloop
 *
 * - Checks if there is another exception handler installed that may block ours
 * - Present UI if the user has to approve new crash reports
 * - Send pending approved crash reports
 */
- (void)invokeDelayedProcessing {
    if (!PREDHelper.isRunningInAppExtension &&
        [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive) {
        return;
    }
    
    PREDLogDebug(@"Start delayed CrashManager processing");
    
    // was our own exception handler successfully added?
    if (self.exceptionHandler) {
        // get the current top level error handler
        NSUncaughtExceptionHandler *currentHandler = NSGetUncaughtExceptionHandler();
        
        // If the top level error handler differs from our own, then at least another one was added.
        // This could cause exception crashes not to be reported to PreDem. See log message for details.
        if (self.exceptionHandler != currentHandler) {
            PREDLogWarning(@"Another exception handler was added. If this invokes any kind exit() after processing the exception, which causes any subsequent error handler not to be invoked, these crashes will NOT be reported to PreDem!");
        }
    }
    
    if (!_sendingInProgress && [self hasPendingCrashReport]) {
        _sendingInProgress = YES;
        [self sendNextCrashReport];
    }
}
/**
 *  Creates a fake crash report because the app was killed while being in foreground
 */
- (void)createCrashReportForAppKill {
    NSString *fakeReportUUID = PREDHelper.UUID ?: @"???";
    NSString *fakeReporterKey = PREDHelper.UUID ?: @"???";
    
    NSString *fakeReportAppBundleIdentifier = PREDHelper.appBundleId;
    NSString *fakeReportDeviceModel = PREDHelper.deviceModel ?: @"Unknown";
    
    NSString *fakeSignalName = kPREDCrashKillSignal;
    
    NSMutableString *fakeReportString = [NSMutableString string];
    
    [fakeReportString appendFormat:@"Incident Identifier: %@\n", fakeReportUUID];
    [fakeReportString appendFormat:@"CrashReporter Key:   %@\n", fakeReporterKey];
    [fakeReportString appendFormat:@"Hardware Model:      %@\n", fakeReportDeviceModel];
    [fakeReportString appendFormat:@"Identifier:      %@\n", fakeReportAppBundleIdentifier];
    
    NSString *fakeReportAppVersionString = [NSString stringWithFormat:@"%@ (%@)", PREDHelper.appVersion, PREDHelper.appBuild];
    
    [fakeReportString appendFormat:@"Version:         %@\n", fakeReportAppVersionString];
    [fakeReportString appendString:@"Code Type:       ARM\n"];
    [fakeReportString appendString:@"\n"];
    
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    NSDateFormatter *rfc3339Formatter = [[NSDateFormatter alloc] init];
    [rfc3339Formatter setLocale:enUSPOSIXLocale];
    [rfc3339Formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    [rfc3339Formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *fakeCrashTimestamp = [rfc3339Formatter stringFromDate:[NSDate date]];
    
    // we use the current date, since we don't know when the kill actually happened
    [fakeReportString appendFormat:@"Date/Time:       %@\n", fakeCrashTimestamp];
    [fakeReportString appendFormat:@"OS Version:      %@\n", PREDHelper.osVersion];
    [fakeReportString appendString:@"Report Version:  104\n"];
    [fakeReportString appendString:@"\n"];
    [fakeReportString appendFormat:@"Exception Type:  %@\n", fakeSignalName];
    [fakeReportString appendString:@"Exception Codes: 00000020 at 0x8badf00d\n"];
    [fakeReportString appendString:@"\n"];
    [fakeReportString appendString:@"Application Specific Information:\n"];
    [fakeReportString appendString:@"The application did not terminate cleanly but no crash occured."];
    if (self.didReceiveMemoryWarningInLastSession) {
        [fakeReportString appendString:@" The app received at least one Low Memory Warning."];
    }
    [fakeReportString appendString:@"\n\n"];
    
    NSString *fakeReportFilename = [NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate]];
    
    NSError *error = nil;
    
    NSMutableDictionary *rootObj = [NSMutableDictionary dictionaryWithCapacity:2];
    [rootObj setObject:fakeReportString forKey:kPREDFakeCrashReport];
    
    NSData *plist = [NSPropertyListSerialization dataWithPropertyList:(id)rootObj
                                                               format:NSPropertyListBinaryFormat_v1_0
                                                              options:0
                                                                error:&error];
    if (!plist || ![plist writeToFile:[_crashesDir stringByAppendingPathComponent:[fakeReportFilename stringByAppendingPathExtension:@"fake"]] atomically:YES]) {
        PREDLogError(@"Writing fake crash report error: %@", error ?: @"unknown");
    }
}

/**
 *	 Send all approved crash reports
 *
 * Gathers all collected data and constructs the XML structure and starts the sending process
 */
- (void)sendNextCrashReport {
    NSError *error = NULL;
    
    if ([_crashFiles count] == 0)
        return;
    
    NSString *crashXML = nil;
    
    // we start sending always with the oldest pending one
    NSString *filename = [_crashFiles objectAtIndex:0];
    NSString *cacheFilename = [filename lastPathComponent];
    NSData *crashData = [NSData dataWithContentsOfFile:filename];
    
    if ([crashData length] > 0) {
        PREPLCrashReport *report = nil;
        NSString *crashUUID = @"";
        NSString *installString = nil;
        NSString *crashLogString = nil;
        NSString *appBundleIdentifier = nil;
        NSString *appBundleMarketingVersion = nil;
        NSString *appBundleVersion = nil;
        NSString *osVersion = nil;
        NSString *deviceModel = nil;
        NSString *appBinaryUUIDs = nil;
        
        NSPropertyListFormat format;
        
        if ([[cacheFilename pathExtension] isEqualToString:@"fake"]) {
            NSDictionary *fakeReportDict = (NSDictionary *)[NSPropertyListSerialization
                                                            propertyListWithData:crashData
                                                            options:NSPropertyListMutableContainersAndLeaves
                                                            format:&format
                                                            error:&error];
            
            crashLogString = [fakeReportDict objectForKey:kPREDFakeCrashReport];
            crashUUID = PREDHelper.UUID;
            appBundleIdentifier = PREDHelper.appBundleId;
            appBundleMarketingVersion = PREDHelper.appVersion;
            appBundleVersion = PREDHelper.appBuild;
            appBinaryUUIDs = PREDHelper.UUID;
            deviceModel = PREDHelper.deviceModel;
            osVersion = PREDHelper.osVersion;
        } else {
            report = [[PREPLCrashReport alloc] initWithData:crashData error:&error];
        }
        
        if (report == nil && crashLogString == nil) {
            PREDLogWarning(@"WARNING: Could not parse crash report");
            // we cannot do anything with this report, so delete it
            [self cleanCrashReportWithFilename:filename];
            // we don't continue with the next report here, even if there are to prevent calling sendCrashReports from itself again
            // the next crash will be automatically send on the next app start/becoming active event
            return;
        }
        
        installString = PREDHelper.UUID ?: @"";
        
        if (report) {
            if (report.uuidRef != NULL) {
                crashUUID = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef));
            }
            crashLogString = [PREDCrashReportTextFormatter stringValueForCrashReport:report crashReporterKey:installString];
            appBundleIdentifier = report.applicationInfo.applicationIdentifier;
            appBundleMarketingVersion = report.applicationInfo.applicationMarketingVersion ?: @"";
            appBundleVersion = report.applicationInfo.applicationVersion;
            osVersion = report.systemInfo.operatingSystemVersion;
            deviceModel = PREDHelper.deviceModel;
            appBinaryUUIDs = [PREDCrashReportTextFormatter extractAppUUIDs:report];
        }
        
        crashXML = [NSString stringWithFormat:@"<crashes><crash><applicationname><![CDATA[%@]]></applicationname><uuids>%@</uuids><bundleidentifier>%@</bundleidentifier><systemversion>%@</systemversion><platform>%@</platform><senderversion>%@</senderversion><versionstring>%@</versionstring><version>%@</version><uuid>%@</uuid><log><![CDATA[%@]]></log><installstring>%@</installstring></crash></crashes>",
                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"],
                    appBinaryUUIDs,
                    appBundleIdentifier,
                    osVersion,
                    deviceModel,
                    [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"],
                    appBundleMarketingVersion,
                    appBundleVersion,
                    crashUUID,
                    [crashLogString stringByReplacingOccurrencesOfString:@"]]>" withString:@"]]" @"]]><![CDATA[" @">" options:NSLiteralSearch range:NSMakeRange(0,crashLogString.length)],
                    installString];
        
        PREDLogDebug(@"Sending crash reports:\n%@", crashXML);
        [self sendCrashReportWithFilename:filename xml:crashXML];
    } else {
        // we cannot do anything with this report, so delete it
        [self cleanCrashReportWithFilename:filename];
    }
}

#pragma clang diagnostic pop

#pragma mark - Networking

- (NSData *)postBodyWithXML:(NSString *)xml boundary:(NSString *)boundary {
    NSMutableData *postBody =  [NSMutableData data];
    
    //  [postBody appendData:[[NSString stringWithFormat:@"\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
    [postBody appendData:[PREDNetworkClient dataWithPostValue:PREDHelper.appName
                                                       forKey:@"sdk"
                                                     boundary:boundary]];
    
    [postBody appendData:[PREDNetworkClient dataWithPostValue:[PREDVersion getSDKVersion]
                                                       forKey:@"sdk_version"
                                                     boundary:boundary]];
    
    [postBody appendData:[PREDNetworkClient dataWithPostValue:@"no"
                                                       forKey:@"feedbackEnabled"
                                                     boundary:boundary]];
    
    [postBody appendData:[PREDNetworkClient dataWithPostValue:[xml dataUsingEncoding:NSUTF8StringEncoding]
                                                       forKey:@"xml"
                                                  contentType:@"text/xml"
                                                     boundary:boundary
                                                     filename:@"crash.xml"]];
    
    [postBody appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return postBody;
}

- (NSMutableURLRequest *)requestWithBoundary:(NSString *)boundary {
    NSString *postCrashPath = @"crashes/i";
    
    NSMutableURLRequest *request = [self.networkClient requestWithMethod:@"POST"
                                                                    path:postCrashPath
                                                              parameters:nil];
    
    [request setCachePolicy: NSURLRequestReloadIgnoringLocalCacheData];
    [request setValue:@"PreDemObjc/iOS" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
    [request setValue:contentType forHTTPHeaderField:@"Content-type"];
    
    return request;
}

// process upload response
- (void)processUploadResultWithFilename:(NSString *)filename responseData:(NSData *)responseData statusCode:(NSInteger)statusCode error:(NSError *)error {
    __block NSError *theError = error;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        _sendingInProgress = NO;
        
        if (nil == theError) {
            if (nil == responseData || [responseData length] == 0) {
                theError = [NSError errorWithDomain:kPREDCrashErrorDomain
                                               code:PREDCrashAPIReceivedEmptyResponse
                                           userInfo:@{
                                                      NSLocalizedDescriptionKey: @"Sending failed with an empty response!"
                                                      }
                            ];
            } else if (statusCode >= 200 && statusCode < 400) {
                [self cleanCrashReportWithFilename:filename];
                
                // PreDem uses PList XML format
                NSMutableDictionary *response = [NSPropertyListSerialization propertyListWithData:responseData
                                                                                          options:NSPropertyListMutableContainersAndLeaves
                                                                                           format:nil
                                                                                            error:&theError];
                PREDLogDebug(@"Received API response: %@", response);
                
                // only if sending the crash report went successfully, continue with the next one (if there are more)
                [self sendNextCrashReport];
            } else if (statusCode == 400) {
                [self cleanCrashReportWithFilename:filename];
                
                theError = [NSError errorWithDomain:kPREDCrashErrorDomain
                                               code:PREDCrashAPIAppVersionRejected
                                           userInfo:@{
                                                      NSLocalizedDescriptionKey: @"The server rejected receiving crash reports for this app version!"
                                                      }
                            ];
            } else {
                theError = [NSError errorWithDomain:kPREDCrashErrorDomain
                                               code:PREDCrashAPIErrorWithStatusCode
                                           userInfo:@{
                                                      NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Sending failed with status code: %li", (long)statusCode]
                                                      }
                            ];
            }
        }
        
        if (theError) {
            PREDLogError(@"%@", [theError localizedDescription]);
        }
    });
}

/**
 *	 Send the XML data to the server
 *
 * Wraps the XML structure into a POST body and starts sending the data asynchronously
 *
 *	@param	xml	The XML data that needs to be send to the server
 */
- (void)sendCrashReportWithFilename:(NSString *)filename xml:(NSString*)xml {
    BOOL sendingWithURLSession = NO;
    
    if ([PREDHelper isURLSessionSupported]) {
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        __block NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
        
        NSURLRequest *request = [self requestWithBoundary:kPREDNetworkClientBoundary];
        NSData *data = [self postBodyWithXML:xml boundary:kPREDNetworkClientBoundary];
        
        if (request && data) {
            __weak typeof (self) weakSelf = self;
            NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                       fromData:data
                                                              completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
                                                                  typeof (self) strongSelf = weakSelf;
                                                                  
                                                                  [session finishTasksAndInvalidate];
                                                                  
                                                                  NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*) response;
                                                                  NSInteger statusCode = [httpResponse statusCode];
                                                                  [strongSelf processUploadResultWithFilename:filename responseData:responseData statusCode:statusCode error:error];
                                                              }];
            
            [uploadTask resume];
            sendingWithURLSession = YES;
        }
    }
    
    if (!sendingWithURLSession) {
        NSMutableURLRequest *request = [self requestWithBoundary:kPREDNetworkClientBoundary];
        
        NSData *postBody = [self postBodyWithXML:xml boundary:kPREDNetworkClientBoundary];
        [request setHTTPBody:postBody];
        
        __weak typeof (self) weakSelf = self;
        PREDHTTPOperation *operation = [self.networkClient
                                        operationWithURLRequest:request
                                        completion:^(PREDHTTPOperation *operation, NSData* responseData, NSError *error) {
                                            typeof (self) strongSelf = weakSelf;
                                            
                                            NSInteger statusCode = [operation.response statusCode];
                                            [strongSelf processUploadResultWithFilename:filename responseData:responseData statusCode:statusCode error:error];
                                        }];
        
        [self.networkClient enqeueHTTPOperation:operation];
    }
    
    PREDLogDebug(@"Sending crash reports started.");
}

@end
