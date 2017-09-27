//
//  PREDCrashManager.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDCrashManager.h"
#import "PREDemObjc.h"
#import "PREDHelper.h"
#import "PREDCrashCXXExceptionHandler.h"
#import "PREDLogger.h"
#import "PREDCrashMeta.h"
#import <CrashReporter/CrashReporter.h>

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

@end


// C++ Exception Handler
static void uncaught_cxx_exception_handler(const PREDCrashUncaughtCXXExceptionInfo *info) {
    // This relies on a LOT of sneaky internal knowledge of how PLCR works and should not be considered a long-term solution.
    NSGetUncaughtExceptionHandler()([[PREDCrashCXXExceptionWrapperException alloc] initWithCXXExceptionInfo:info]);
    abort();
}


@implementation PREDCrashManager {
    PREDPersistence *_persistence;
    PREDPLCrashReporter *_plCrashReporter;
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence {
    if ((self = [super init])) {
        _persistence = persistence;
    }
    return self;
}

#pragma mark - Public

- (void)setStarted:(BOOL)started {
    if (_started == started) {
        return;
    }
    _started = started;
    if (started) {
        PREDLogDebug(@"Starting CrashManager");
                
        PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
        
        PLCrashReporterSymbolicationStrategy symbolicationStrategy = PLCrashReporterSymbolicationStrategyNone;
        if (self.isOnDeviceSymbolicationEnabled) {
            symbolicationStrategy = PLCrashReporterSymbolicationStrategyAll;
        }
        
        PREDPLCrashReporterConfig *config = [[PREDPLCrashReporterConfig alloc] initWithSignalHandlerType: signalHandlerType symbolicationStrategy: symbolicationStrategy];
        _plCrashReporter = [[PREDPLCrashReporter alloc] initWithConfiguration: config];
        
        // Check if we previously crashed
        
        [self handleCrashReport];
        
        
        if (PREDHelper.isDebuggerAttached) {
            PREDLogWarn(@"Detecting crashes is NOT enabled due to running the app with a debugger attached.");
        } else {
            // PLCrashReporter may only be initialized once. So make sure the developer
            // can't break this
            NSError *error = NULL;
            
            // Enable the Crash Reporter
            if (![_plCrashReporter enableCrashReporterAndReturnError: &error]) {
                PREDLogError(@"Could not enable crash reporter: %@", [error localizedDescription]);
            }
            
            // Add the C++ uncaught exception handler, which is currently not handled by PLCrashReporter internally
            [PREDCrashUncaughtCXXExceptionHandlerManager addCXXExceptionHandler:uncaught_cxx_exception_handler];
        }
    } else {
        PREDLogDebug(@"Terminating CrashManager");
        [PREDCrashUncaughtCXXExceptionHandlerManager removeCXXExceptionHandler:uncaught_cxx_exception_handler];
    }
}

#pragma mark - PLCrashReporter

/**
 *	 Process new crash reports provided by PLCrashReporter
 *
 */
- (void)handleCrashReport {
    if ([_plCrashReporter hasPendingCrashReport]) {
        PREDLogVerbose(@"Handling crash report");
        NSError *error;
        
        // Try loading the crash report
        NSData *data = [_plCrashReporter loadPendingCrashReportDataAndReturnError:&error];
        
        if (error) {
            PREDLogError(@"Could not load crash report: %@", error);
        } else {
            PREDCrashMeta *meta = [[PREDCrashMeta alloc] initWithData:data error:&error];
            if (error) {
                PREDLogError(@"Could not parse crash report: %@", error);
            } else {
                [_persistence persistCrashMeta:meta];
            }
        }
        [_plCrashReporter purgePendingCrashReport];
    }
}

@end
