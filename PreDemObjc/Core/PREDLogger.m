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
#import "PREDLogFormatter.h"
#import "PREDLogFileManager.h"
#import "PREDLoggerPrivate.h"
#import "PREDLogMeta.h"
#import "PREDPersistence.h"
#import "PREDManager.h"
#import "PREDError.h"

#define PREDMillisecondPerSecond        1000

@implementation PREDLogger {
    BOOL _started;
    DDLog *_ddLog;
    DDFileLogger *_fileLogger;
    DDTTYLogger *_ttyLogger;
    PREDLogLevel _ttyLogLevel;
    PREDLogLevel _fileLogLevel;
    PREDPersistence *_persistence;
    PREDLogFileManager *_logFileManager;
    PREDLogFormatter *_ttyLogFormatter;
    PREDLogFormatter *_fileLogFormatter;
    PREDLogMeta *_currentMeta;
}

+ (instancetype)sharedLogger {
    static PREDLogger *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[PREDLogger alloc] init];
    });
    return logger;
}

+ (void)log:(BOOL)asynchronous
      level:(PREDLogLevel)level
       flag:(PREDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... {
    va_list args;
    if (format) {
        va_start(args, format);
        [[PREDLogger sharedLogger]->_ddLog log:asynchronous level:(DDLogLevel)level flag:(DDLogFlag)flag context:context file:file function:function line:line tag:tag format:format, args];
        va_end(args);
    }
}

+ (void)setStarted:(BOOL)started {
    [PREDLogger sharedLogger].started = started;
}

- (void)setStarted:(BOOL)started {
    if (_started == started) {
        return;
    }
    _started = started;
    if (started) {
        _ttyLogger.logFormatter = _ttyLogFormatter;
        [_ddLog addLogger:_ttyLogger];
    } else {
        [_ddLog removeLogger:_ttyLogger];
    }
}

+ (BOOL)started {
    return [PREDLogger sharedLogger].started;
}

- (BOOL)started {
    return _started;
}

+ (DDLog *)ddLog {
    return [PREDLogger sharedLogger]->_ddLog;
}

- (instancetype)init {
    if (self = [super init]) {
        _ddLog = [[DDLog alloc] init];
        _ttyLogger = [[DDTTYLogger alloc] init];
        _ttyLogLevel = PREDLogLevelAll;
        _logFileManager = [[PREDLogFileManager alloc] initWithLogsDirectory:[NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"logfiles"]];
        _logFileManager.delegate = self;
        _logFileManager.maximumNumberOfLogFiles = 0;
        _ttyLogFormatter = [[PREDLogFormatter alloc] init];
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
    [_ddLog removeLogger:_ttyLogger];
    [_ddLog addLogger:_ttyLogger withLevel:(DDLogLevel)_ttyLogLevel];
}

+ (PREDLogLevel)ttyLogLevel {
    return [PREDLogger sharedLogger].ttyLogLevel;
}

- (PREDLogLevel)ttyLogLevel {
    return _ttyLogLevel;
}

+ (BOOL)startCaptureLogWithLevel:(PREDLogLevel)logLevel error:(NSError **)error {
    return [[PREDLogger sharedLogger] startCaptureLogWithLevel:logLevel error:error];
}

- (BOOL)startCaptureLogWithLevel:(PREDLogLevel)logLevel error:(NSError **)error {
    if (_fileLogger && _fileLogLevel == logLevel) {
        return YES;
    }
    if (![PREDManager started]) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeNotInitedError description:@"you should init PREDManager first before capturing your log"];
        }
        return NO;
    }
    _fileLogLevel = logLevel;
    [self stopCaptureLog];
    _fileLogger = [[DDFileLogger alloc] initWithLogFileManager:_logFileManager]; // File Logger
    _fileLogger.rollingFrequency = 0;
    _fileLogger.maximumFileSize = 1024 * 512;   // 512 KB
    _fileLogger.doNotReuseLogFiles = YES;
    _fileLogger.logFormatter = _fileLogFormatter;
    [_ddLog addLogger:_fileLogger withLevel:(DDLogLevel)logLevel];
    return YES;
}

+ (void)stopCaptureLog {
    [[PREDLogger sharedLogger] stopCaptureLog];
}

- (void)stopCaptureLog {
    if (_fileLogger) {
        [_ddLog removeLogger:_fileLogger];
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
    [_persistence persistLogMeta:_currentMeta];
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
