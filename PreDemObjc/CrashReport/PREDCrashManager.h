//
//  PREDCrashManager.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CrashReporter/CrashReporter.h>

@class PREDNetworkClient;

typedef NS_ENUM(NSUInteger, PREDCrashManagerStatus) {
    PREDCrashManagerStatusDisabled = 0,
    PREDCrashManagerStatusAlwaysAsk = 1,
    PREDCrashManagerStatusAutoSend = 2
};

typedef void (*PREDCrashManagerPostCrashSignalCallback)(void *context);

typedef struct PREDCrashManagerCallbacks {
    void *context;
    PREDCrashManagerPostCrashSignalCallback handleSignal;
} PREDCrashManagerCallbacks;

typedef NS_ENUM(NSUInteger, PREDCrashManagerUserInput) {
    PREDCrashManagerUserInputDontSend = 0,
    PREDCrashManagerUserInputSend = 1,
    PREDCrashManagerUserInputAlwaysSend = 2
};

@interface PREDCrashManager : NSObject

@property (nonatomic, assign) PREDCrashManagerStatus crashManagerStatus;

@property (nonatomic, assign, getter=isMachExceptionHandlerEnabled) BOOL enableMachExceptionHandler;

@property (nonatomic, assign, getter=isOnDeviceSymbolicationEnabled) BOOL enableOnDeviceSymbolication;

@property (nonatomic, assign, getter = isAppNotTerminatingCleanlyDetectionEnabled) BOOL enableAppNotTerminatingCleanlyDetection;

@property (nonatomic, assign, getter=shouldShowAlwaysButton) BOOL showAlwaysButton;

@property (nonatomic, readonly) BOOL didCrashInLastSession;

@property (nonatomic, readonly) BOOL didReceiveMemoryWarningInLastSession;

@property (nonatomic, readonly) NSTimeInterval timeIntervalCrashInLastSessionOccurred;

@property (nonatomic, strong) PREDNetworkClient *hockeyAppClient;

@property (nonatomic) NSUncaughtExceptionHandler *exceptionHandler;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic, strong) PREPLCrashReporter *plCrashReporter;

@property (nonatomic) NSString *lastCrashFilename;

@property (nonatomic, strong) NSString *crashesDir;

@property (nonatomic, copy) NSString *serverURL;

@property (nonatomic, strong) NSString *appIdentifier;

- (instancetype)initWithAppIdentifier:(NSString *)appIdentifier hockeyAppClient:(PREDNetworkClient *)hockeyAppClient;

- (void)startManager;

- (void)setCrashCallbacks: (PREDCrashManagerCallbacks *) callbacks;

@end
