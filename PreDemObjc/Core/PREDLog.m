//
//  PREDLog.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLog.h"
#import "PREDHelper.h"
#import "PREDNetworkClient.h"
#import "PREDLogFormatter.h"
#import "PREDLogFileManager.h"
#import "PREDLogPrivate.h"
#import "PREDLogMeta.h"
#import "PREDPersistence.h"
#import "PREDManager.h"
#import "PREDError.h"

#define PREDMillisecondPerSecond        1000

static __weak id<PREDLogDelegate> _delegate;

@implementation PREDLog {
    BOOL _started;
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

+ (instancetype)sharedInstance {
    static PREDLog *logger;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[PREDLog alloc] init];
    });
    return logger;
}

+ (void)log:(BOOL)asynchronous
      level:(DDLogLevel)level
       flag:(DDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... {
    va_list args;
    if (format) {
        va_start(args, format);
        DDLogMessage *message = [[DDLogMessage alloc] initWithMessage:[[NSString alloc] initWithFormat:format arguments:args] level:(DDLogLevel)level flag:(DDLogFlag)flag context:context file:[NSString stringWithFormat:@"%s", file] function:[NSString stringWithFormat:@"%s", function] line:line tag:tag options:0 timestamp:nil];
        va_end(args);
        [[PREDLog sharedInstance] log:asynchronous message:message];
    }
}

- (void)log:(BOOL)asynchronous
    message:(DDLogMessage *)logMessage {
    if([_delegate respondsToSelector:@selector(log:didReceivedLogMessage:formattedLog:)]) {
        [_delegate log:[PREDLog sharedInstance] didReceivedLogMessage:logMessage formattedLog:[[PREDLog sharedInstance]->_ttyLogFormatter formatLogMessage:logMessage]];
    }
    [super log:asynchronous message:logMessage];
}

+ (void)setStarted:(BOOL)started {
    [PREDLog sharedInstance].started = started;
}

- (void)setStarted:(BOOL)started {
    if (_started == started) {
        return;
    }
    _started = started;
    if (started) {
        _ttyLogger.logFormatter = _ttyLogFormatter;
        [self addLogger:_ttyLogger];
    } else {
        [self removeLogger:_ttyLogger];
    }
}

+ (BOOL)started {
    return [PREDLog sharedInstance].started;
}

- (BOOL)started {
    return _started;
}

+ (void)setDelegate:(id<PREDLogDelegate>)delegate {
    _delegate = delegate;
}

+ (id<PREDLogDelegate>)delegate {
    return _delegate;
}

- (instancetype)init {
    if (self = [super init]) {
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
    [PREDLog sharedInstance].ttyLogLevel = ttyLogLevel;
}

- (void)setTtyLogLevel:(PREDLogLevel)ttyLogLevel {
    if (_ttyLogLevel == ttyLogLevel) {
        return;
    }
    _ttyLogLevel = ttyLogLevel;
    [self removeLogger:_ttyLogger];
    [self addLogger:_ttyLogger withLevel:(DDLogLevel)_ttyLogLevel];
}

+ (PREDLogLevel)ttyLogLevel {
    return [PREDLog sharedInstance].ttyLogLevel;
}

- (PREDLogLevel)ttyLogLevel {
    return _ttyLogLevel;
}

+ (BOOL)startCaptureLogWithLevel:(PREDLogLevel)logLevel error:(NSError **)error {
    return [[PREDLog sharedInstance] startCaptureLogWithLevel:logLevel error:error];
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
    [self addLogger:_fileLogger withLevel:(DDLogLevel)logLevel];
    return YES;
}

+ (void)stopCaptureLog {
    [[PREDLog sharedInstance] stopCaptureLog];
}

- (void)stopCaptureLog {
    if (_fileLogger) {
        [self removeLogger:_fileLogger];
        _fileLogger = nil;
    }
}

+ (void)setPersistence:(PREDPersistence *)persistence {
    [PREDLog sharedInstance].persistence = persistence;
}

+ (PREDPersistence *)persistence {
    return [PREDLog sharedInstance].persistence;
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
