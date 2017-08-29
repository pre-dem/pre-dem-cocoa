//
//  PREDLogger.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLogger.h"
#import "PreDemObjc.h"

static DDLogLevel _logLevel = DDLogLevelAll;
static DDFileLogger *_fileLogger;

@implementation PREDLogger

+ (void)load {
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:_logLevel];
}

+ (void)setLogLevel:(DDLogLevel)logLevel {
    if (_logLevel == logLevel) {
        return;
    }
    _logLevel = logLevel;
    [DDLog removeLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:_logLevel];
}

+ (DDLogLevel)logLevel {
    return _logLevel;
}

+ (void)startCaptureLogWithLevel:(DDLogLevel)logLevel {
    _fileLogger = [[DDFileLogger alloc] init]; // File Logger
    _fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    _fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:_fileLogger withLevel:logLevel];
}

+ (void)stopCaptureLog {
    [DDLog removeLogger:_fileLogger];
}

@end
