//
//  PREDLogger.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLogger.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import <Qiniu/QiniuSDK.h>
#import "PREDLogFormatter.h"
#import "PREDLogFileManager.h"
#import "PREDLoggerPrivate.h"
#import "PREDLogMeta.h"
#import "PREDPersistence.h"

#define DefaltTtyLogLevel               DDLogLevelAll
#define PREDMillisecondPerSecond        1000

@implementation PREDLogger {
    PREDLogLevel _ttyLogLevel;
    PREDLogLevel _fileLogLevel;
    DDFileLogger *_fileLogger;
    PREDPersistence *_persistence;
    QNUploadManager *_uploadManager;
    PREDLogFileManager *_logFileManager;
    PREDLogFormatter *_fileLogFormatter;
    PREDLogMeta *_currentMeta;
}

+ (void)load {
    [DDTTYLogger sharedInstance].logFormatter = [[PREDLogFormatter alloc] init];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:DefaltTtyLogLevel];
}

+ (instancetype)sharedLogger {
    static PREDLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[PREDLogger alloc] init];
    });
    return logger;
}

- (instancetype)init {
    if (self = [super init]) {
        _ttyLogLevel = (PREDLogLevel)DefaltTtyLogLevel;
        _uploadManager = [[QNUploadManager alloc] init];
        _logFileManager = [[PREDLogFileManager alloc] initWithLogsDirectory:[NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"logfiles"]];
        _logFileManager.delegate = self;
        _fileLogFormatter = [[PREDLogFormatter alloc] init];
        _fileLogFormatter.delegate = self;
    }
    return self;
}

+ (void)setTtyLogLevel:(PREDLogLevel)ttyLogLevel {
    [PREDLogger sharedLogger].ttyLogLevel = ttyLogLevel;
}

- (void)setTtyLogLevel:(PREDLogLevel)ttyLogLevel {
    if (_ttyLogLevel == ttyLogLevel) {
        return;
    }
    _ttyLogLevel = ttyLogLevel;
    [DDLog removeLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:(DDLogLevel)_ttyLogLevel];
}

+ (PREDLogLevel)ttyLogLevel {
    return [PREDLogger sharedLogger].ttyLogLevel;
}

- (PREDLogLevel)ttyLogLevel {
    return _ttyLogLevel;
}

+ (void)startCaptureLogWithLevel:(PREDLogLevel)logLevel {
    [[PREDLogger sharedLogger] startCaptureLogWithLevel:logLevel];
}

- (void)startCaptureLogWithLevel:(PREDLogLevel)logLevel {
    if (_fileLogger && _fileLogLevel == logLevel) {
        return;
    }
    _fileLogLevel = logLevel;
    [self stopCaptureLog];
    _fileLogger = [[DDFileLogger alloc] initWithLogFileManager:_logFileManager]; // File Logger
    _fileLogger.rollingFrequency = 0;
    _fileLogger.maximumFileSize = 1024 * 512;   // 512 KB
    _fileLogger.doNotReuseLogFiles = YES;
    _fileLogger.logFormatter = _fileLogFormatter;
    [DDLog addLogger:_fileLogger withLevel:(DDLogLevel)logLevel];
}

+ (void)stopCaptureLog {
    [[PREDLogger sharedLogger] stopCaptureLog];
}

- (void)stopCaptureLog {
    if (_fileLogger) {
        [DDLog removeLogger:_fileLogger];
        _fileLogger = nil;
    }
}

+ (void)setPersistence:(PREDPersistence *)persistence {
    [PREDLogger sharedLogger].persistence = persistence;
}

+ (PREDPersistence *)persistence {
    return [PREDLogger sharedLogger].persistence;
}

- (void)setPersistence:(PREDPersistence *)persistence {
    _persistence = persistence;
}

- (PREDPersistence *)persistence {
    return _persistence;
}

- (void)logFileManager:(PREDLogFileManager *)logFileManager willCreatedNewLogFile:(NSString *)logFileName {
    _currentMeta = [[PREDLogMeta alloc] init];
    _currentMeta.log_key = logFileName;
}

- (void)logFileManager:(PREDLogFileManager *)logFileManager willArchiveLogFile:(NSString *)logFileName {
    if (![_currentMeta.log_key isEqualToString:logFileName]) {
        _currentMeta.log_key = logFileName;
        [_persistence persistLogMeta:_currentMeta];
    }
}

- (void)logFormatter:(PREDLogFormatter *)logFormatter willFormatMessage:(DDLogMessage *)logMessage {
    @synchronized (self) {
        // because DDFileLogger will format message before create new file, so we move creation process ahead
        [_fileLogger currentLogFileInfo];
        BOOL needRefreshPersistence = NO;
        if (logMessage.flag == DDLogFlagError) {
            _currentMeta.error_count++;
            needRefreshPersistence = YES;
        }
        if ([logMessage.tag respondsToSelector:@selector(description)]) {
            BOOL exist = [_currentMeta addLogTag:[NSString stringWithFormat:@"%@", logMessage.tag]];
            if (!exist) {
                needRefreshPersistence = YES;
            }
        }
        if (needRefreshPersistence) {
            [_persistence persistLogMeta:_currentMeta];
        }
    }
}

@end
