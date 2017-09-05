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

#define LogCaptureUploadRetryInterval   100
#define LogCaptureUploadMaxTimes        5
#define DefaltTtyLogLevel               DDLogLevelAll

@implementation PREDLogger {
    PREDLogLevel _ttyLogLevel;
    PREDLogLevel _fileLogLevel;
    DDFileLogger *_fileLogger;
    PREDNetworkClient *_networkClient;
    QNUploadManager *_uploadManager;
    NSDate *_logStartTime;
    PREDLogFileManager *_logFileManagers;
    NSDateFormatter *_rfc3339Formatter;
    PREDLogFormatter *_fileLogFormatter;
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
        _rfc3339Formatter = [[NSDateFormatter alloc] init];
        [_rfc3339Formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [_rfc3339Formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        _fileLogFormatter = [[PREDLogFormatter alloc] init];
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

+ (void)setNetworkClient:(PREDNetworkClient *)networkClient {
    [PREDLogger sharedLogger].networkClient = networkClient;
}

- (void)setNetworkClient:(PREDNetworkClient *)networkClient {
    _networkClient = networkClient;
}

+ (PREDNetworkClient *)networkClient {
    return [PREDLogger sharedLogger].networkClient;
}

- (PREDNetworkClient *)networkClient {
    return _networkClient;
}

- (void)logFileManager:(PREDLogFileManager *)logFileManager didArchivedLogFile:(NSString *)logFilePath {
    [self uploadLog:logFilePath startTime:[_rfc3339Formatter stringFromDate:_logStartTime] endTime:[_rfc3339Formatter stringFromDate:[NSDate date]] retryTimes:0];
    _logStartTime = [NSDate date];
}

- (void)uploadLog:(NSString *)logFilePath startTime:(NSString *)startTime endTime:(NSString *)endTime retryTimes:(NSUInteger)retryTimes {
    NSError *err;
    NSString *log = [NSString stringWithContentsOfFile:logFilePath encoding:NSUTF8StringEncoding error:&err];
    if (err) {
        return;
    }
    NSString *md5 = [PREDHelper MD5:log];
    NSDictionary *param = @{@"md5": md5};
    [_networkClient getPath:@"log-capture-token/i" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        if (!error) {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!error && operation.response.statusCode < 400 && dic && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
                [_uploadManager
                 putData:[log dataUsingEncoding:NSUTF8StringEncoding]
                 key:[dic valueForKey:@"key"]
                 token:[dic valueForKey:@"token"]
                 complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                     if (resp) {
                         NSDictionary *metadata = @{
                                                    @"app_bundle_id": PREDHelper.appBundleId,
                                                    @"app_name": PREDHelper.appName,
                                                    @"app_version": PREDHelper.appVersion,
                                                    @"device_model": PREDHelper.deviceModel,
                                                    @"os_platform": PREDHelper.osPlatform,
                                                    @"os_version": PREDHelper.osVersion,
                                                    @"os_build": PREDHelper.osBuild,
                                                    @"sdk_version": PREDHelper.sdkVersion,
                                                    @"sdk_id": PREDHelper.UUID,
                                                    @"tag": PREDHelper.tag,
                                                    @"manufacturer": @"Apple",
                                                    @"start_time": startTime,
                                                    @"end_time": endTime,
                                                    @"log_key": key,
                                                    };
                         [_networkClient postPath:@"log-capture/i" parameters:metadata completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                             if (error || operation.response.statusCode >= 400) {
                                 PREDLogError(@"upload lag metadata fail: %@ code: %ld, drop report", error?:@"unknown", (long)operation.response.statusCode);
                             } else {
                                 PREDLogDebug(@"upload lag report succeed");
                             }
                         }];
                     } else if (retryTimes < LogCaptureUploadMaxTimes) {
                         PREDLogWarn(@"upload log fail: %@, retry after: %d seconds", info.error, LogCaptureUploadRetryInterval);
                         dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(LogCaptureUploadRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                             [self uploadLog:logFilePath startTime:startTime endTime:endTime retryTimes:retryTimes+1];
                             return;
                         });
                     } else {
                         PREDLogError(@"upload log fail: %@, drop report", error);
                         return;
                     }
                 }
                 option:nil];
            } else {
                PREDLogError(@"get upload token fail: %@, drop report", error);
                return;
            }
        } else {
            PREDLogError(@"get upload token fail: %@, drop report", error);
            return;
        }
    }];
}

@end
