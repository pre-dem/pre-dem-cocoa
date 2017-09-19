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
    NSDate *_logStartTime;
    PREDLogFileManager *_logFileManagers;
    PREDLogFormatter *_fileLogFormatter;
    NSUInteger _errorLogCount;
    NSMutableSet *_logTags;
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
        _logFileManagers = [[PREDLogFileManager alloc] init];
        _logFileManagers.delegate = self;
        _fileLogFormatter = [[PREDLogFormatter alloc] init];
        _fileLogFormatter.delegate = self;
        _logTags = [[NSMutableSet alloc] init];
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
    _fileLogger = [[DDFileLogger alloc] initWithLogFileManager:_logFileManagers]; // File Logger
    _fileLogger.rollingFrequency = 0;
    _fileLogger.maximumFileSize = 1024 * 512;   // 512 KB
    _fileLogger.logFormatter = _fileLogFormatter;
    [DDLog addLogger:_fileLogger withLevel:(DDLogLevel)logLevel];
    _logStartTime = [NSDate date];
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

- (void)logFileManager:(PREDLogFileManager *)logFileManager didArchivedLogFile:(NSString *)logFilePath {
    PREDLogMeta *meta;
    @synchronized (self) {
        meta = [[PREDLogMeta alloc] initWithLogKey:logFilePath startTime:[_logStartTime timeIntervalSince1970] * PREDMillisecondPerSecond endTime:[[NSDate date] timeIntervalSince1970] * PREDMillisecondPerSecond logTags:[self logTagsString] ?: @"" errorCount:_errorLogCount];
        [_logTags removeAllObjects];
        _errorLogCount = 0;
    }
    [_persistence persistLogMeta:meta];
    _logStartTime = [NSDate date];
}

- (void)logFormatter:(PREDLogFormatter *)logFormatter willFormatMessage:(DDLogMessage *)logMessage {
    @synchronized (self) {
        if (logMessage.flag == DDLogFlagError) {
            _errorLogCount++;
        }
        if ([logMessage.tag respondsToSelector:@selector(description)]) {
            [_logTags addObject:[NSString stringWithFormat:@"%@", logMessage.tag]];
        }
    }
}

- (NSString *)logTagsString {
    __block NSString *result;
    [_logTags enumerateObjectsUsingBlock:^(NSString* obj, BOOL * stop) {
        if (!result) {
            result = obj;
        } else {
            result = [NSString stringWithFormat:@"%@\t%@", result, obj];
        }
    }];
    return result;
}

@end
