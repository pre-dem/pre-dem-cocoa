//
//  PREDLogger.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLogger.h"
#import "PreDemObjc.h"

static PREDLogLevel _logLevel = PREDLogLevelAll;
static DDFileLogger *_fileLogger;

@interface PREDLogFileManager : DDLogFileManagerDefault

@end

@implementation PREDLogFileManager

- (void)didArchiveLogFile:(NSString *)logFilePath {
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, logFilePath);
}

- (void)didRollAndArchiveLogFile:(NSString *)logFilePath {
    NSLog(@"%s, %@", __PRETTY_FUNCTION__, logFilePath);
}

@end

@implementation PREDLogger

+ (void)load {
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:(DDLogLevel)_logLevel];
}

+ (void)setLogLevel:(PREDLogLevel)logLevel {
    if (_logLevel == logLevel) {
        return;
    }
    _logLevel = logLevel;
    [DDLog removeLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:(DDLogLevel)_logLevel];
}

+ (PREDLogLevel)logLevel {
    return _logLevel;
}

+ (void)startCaptureLogWithLevel:(PREDLogLevel)logLevel {
    [self stopCaptureLog];
    PREDLogFileManager *fileManager = [[PREDLogFileManager alloc] init];
    _fileLogger = [[DDFileLogger alloc] initWithLogFileManager:fileManager]; // File Logger
    _fileLogger.rollingFrequency = 10; // 24 hour rolling
    _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:_fileLogger withLevel:(DDLogLevel)logLevel];
}

+ (void)stopCaptureLog {
    if (_fileLogger) {
        [DDLog removeLogger:_fileLogger];
        _fileLogger = nil;
    }
}

@end
