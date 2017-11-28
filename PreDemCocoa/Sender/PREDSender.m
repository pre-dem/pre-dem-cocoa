//
//  PREDSender.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import <Qiniu/QiniuSDK.h>

#import "PREDSender.h"
#import "PREDHelper.h"
#import "PREDLog.h"
#import "PREDConfigManager.h"
#import "NSObject+Serialization.h"

#define PREDSendInterval    30

@implementation PREDSender {
    PREDPersistence *_persistence;
    PREDNetworkClient *_networkClient;
    QNUploadManager *_uploadManager;
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence baseUrl:(NSURL *)baseUrl {
    if (self = [super init]) {
        _persistence = persistence;
        _networkClient = [[PREDNetworkClient alloc] initWithBaseURL:baseUrl];
        QNConfiguration *c = [QNConfiguration build:^(QNConfigurationBuilder *builder) {
            builder.zone = [QNFixedZone zone0];
#ifdef PREDEM_STAGING
            builder.zone = [QNFixedZone createWithHost:@[@"10.200.20.23:5010"] ];
            builder.useHttps = NO;
#endif
        }];
        _uploadManager = [QNUploadManager sharedInstanceWithConfiguration:c];
    }
    return self;
}

- (void)sendAllSavedData {
    PREDLogVerbose(@"trying to send all saved messages");
    [self sendAppInfo];
    [self sendCrashData];
    [self sendLagData];
    [self sendLogData];
    [self sendHttpMonitor];
    [self sendNetDiag];
    [self sendCustomEvents];
    [self sendBreadcrumbs];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PREDSendInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sendAllSavedData];
    });
}

- (void)sendAppInfo {
    NSString *filePath = [_persistence nextAppInfoPath];
    if (!filePath) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        PREDLogError(@"get stored data %@ error", filePath);
        return;
    }
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"app-config" data:data headers:@{@"Content-Type": @"application/json"} completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get config failed: %@", error);
        } else {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if ([dic respondsToSelector:@selector(objectForKey:)]) {
                PREDLogVerbose(@"got config:\n%@", dic);
                [[NSNotificationCenter defaultCenter] postNotificationName:kPREDConfigRefreshedNotification object:self userInfo:@{kPREDConfigRefreshedNotificationConfigKey: dic}];
            } else {
                PREDLogError(@"config received from server has a wrong type: %@", dic);
            }
            [strongSelf->_persistence purgeAllAppInfo];
        }
    }];
}

- (void)sendCrashData {
    NSString *filePath = [_persistence nextCrashMetaPath];
    if (!filePath) {
        return;
    }
    NSError *error;
    NSMutableDictionary *meta = [_persistence getStoredMeta:filePath error:&error];
    if (error) {
        PREDLogError(@"get stored meta %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *content = meta[@"content"];
    if (!content) {
        PREDLogError(@"get meta content %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        PREDLogError(@"parse meta content %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *logString = contentDic[@"crash_log_key"];
    if (!logString) {
        PREDLogError(@"get log string %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *md5 = [PREDHelper MD5:logString];
    NSDictionary *param = @{@"md5": md5};
    __weak typeof(self) wSelf = self;
    [_networkClient getPath:@"crash-report-token" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get crash token error: %@", error);
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
            NSString *key = [dic valueForKey:@"key"];
            NSString *token = [dic valueForKey:@"token"];
            contentDic[@"crash_log_key"] = key;
            NSString *content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:contentDic options:0 error:nil] encoding:NSUTF8StringEncoding];
            meta[@"content"] = content;
            [strongSelf->_uploadManager
             putData:[logString dataUsingEncoding:NSUTF8StringEncoding]
             key:key
             token: token
             complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                 if (resp) {
                     [strongSelf->_networkClient postPath:@"crashes" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                         __strong typeof (wSelf) strongSelf = wSelf;
                         if (!error) {
                             PREDLogDebug(@"Send crash report succeeded");
                             [strongSelf->_persistence purgeFile:filePath];
                             [strongSelf sendCrashData];
                         } else {
                             PREDLogError(@"upload crash meta fail: %@", error);
                         }
                     }];
                 } else {
                     PREDLogError(@"upload crash fail: %@", info.error);
                     return;
                 }
             }
             option:nil];
        } else {
            PREDLogError(@"parse crash upload token error: %@, data: %@", error, dic);
        }
    }];
}

- (void)sendLagData {
    NSString *filePath = [_persistence nextLagMetaPath];
    if (!filePath) {
        return;
    }
    NSError *error;
    NSMutableDictionary *meta = [_persistence getStoredMeta:filePath error:&error];
    if (error) {
        PREDLogError(@"get stored meta %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *content = meta[@"content"];
    if (!content) {
        PREDLogError(@"get meta content %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        PREDLogError(@"parse meta content %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *logString = contentDic[@"lag_log_key"];
    if (!logString) {
        PREDLogError(@"get log string %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *md5 = [PREDHelper MD5:logString];
    NSDictionary *param = @{@"md5": md5};
    __weak typeof(self) wSelf = self;
    [_networkClient getPath:@"lag-report-token" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get lag token error: %@", error);
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
            NSString *key = [dic valueForKey:@"key"];
            NSString *token = [dic valueForKey:@"token"];
            contentDic[@"lag_log_key"] = key;
            NSString *content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:contentDic options:0 error:nil] encoding:NSUTF8StringEncoding];
            meta[@"content"] = content;
            [strongSelf->_uploadManager
             putData:[logString dataUsingEncoding:NSUTF8StringEncoding]
             key:key
             token: token
             complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                 if (resp) {
                     [strongSelf->_networkClient postPath:@"lag-monitor" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                         __strong typeof (wSelf) strongSelf = wSelf;
                         if (!error) {
                             PREDLogDebug(@"Send lag report succeeded");
                             [strongSelf->_persistence purgeFile:filePath];
                             [strongSelf sendLagData];
                         } else {
                             PREDLogError(@"upload lag meta fail: %@", error);
                         }
                     }];
                 } else {
                     PREDLogError(@"upload lag fail: %@", info.error);
                     return;
                 }
             }
             option:nil];
        } else {
            PREDLogError(@"parse lag upload token error: %@, data: %@", error, dic);
        }
    }];
}

- (void)sendLogData {
    NSString *filePath = [_persistence nextLogMetaPath];
    if (!filePath) {
        return;
    }
    NSError *error;
    NSMutableDictionary *meta = [_persistence getLogMeta:filePath error:&error];
    if (error) {
        PREDLogError(@"get stored meta %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *content = meta[@"content"];
    if (!content) {
        PREDLogError(@"get meta content %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    
    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        PREDLogError(@"parse meta content %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSString *logFilePath = contentDic[@"log_key"];
    if (!logFilePath) {
        PREDLogError(@"get log string %@ error %@", filePath, error);
        [_persistence purgeFile:filePath];
        return;
    }
    NSData *logData = [NSData dataWithContentsOfFile:logFilePath];
    NSString *md5 = [PREDHelper MD5ForData:logData];
    NSDictionary *param = @{@"md5": md5};
    __weak typeof(self) wSelf = self;
    [_networkClient getPath:@"log-capture-token" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get log token error: %@", error);
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
            NSString *key = [dic valueForKey:@"key"];
            NSString *token = [dic valueForKey:@"token"];
            contentDic[@"log_key"] = key;
            NSString *content = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:contentDic options:0 error:nil] encoding:NSUTF8StringEncoding];
            meta[@"content"] = content;
            [strongSelf->_uploadManager
             putData:logData
             key:key
             token: token
             complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                 __strong typeof(wSelf) strongSelf = wSelf;
                 if (resp) {
                     [strongSelf->_networkClient postPath:@"log-capture" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                         __strong typeof (wSelf) strongSelf = wSelf;
                         if (!error) {
                             PREDLogDebug(@"Send log report succeeded");
                             [strongSelf->_persistence purgeFile:filePath];
                             [strongSelf->_persistence purgeFile:logFilePath];
                             [strongSelf sendLogData];
                         } else {
                             PREDLogError(@"upload log meta fail: %@", error);
                         }
                     }];
                 } else {
                     PREDLogError(@"upload log fail: %@", info.error);
                     return;
                 }
             }
             option:nil];
        } else {
            PREDLogError(@"parse log upload token error: %@, data: %@", error, dic);
        }
    }];
}

- (void)sendHttpMonitor {
    NSString *filePath = [_persistence nextHttpMonitorPath];
    if (!filePath) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        PREDLogError(@"get stored data %@ error", filePath);
        return;
    }
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"http-monitors" data:data headers:@{@"Content-Type": @"application/json"} completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                      __strong typeof(wSelf) strongSelf = wSelf;
                      if (!error) {
                          PREDLogDebug(@"Send http monitor succeeded");
                          [strongSelf->_persistence purgeFile:filePath];
                          [strongSelf sendHttpMonitor];
                      } else {
                          PREDLogError(@"upload http monitor fail: %@", error);
                      }
                  }];
}

- (void)sendNetDiag {
    NSString *filePath = [_persistence nextNetDiagPath];
    if (!filePath) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        PREDLogError(@"get stored data %@ error", filePath);
        return;
    }
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"net-diags" data:data headers:@{@"Content-Type": @"application/json"} completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
            PREDLogDebug(@"Send net diag succeeded");
            [strongSelf->_persistence purgeFile:filePath];
            [strongSelf sendNetDiag];
        } else {
            PREDLogError(@"send net diag error: %@", error);
        }
    }];
}

- (void)sendCustomEvents {
    NSString *filePath = [_persistence nextArchivedCustomEventsPath];
    if (!filePath) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data.length) {
        PREDLogError(@"get stored data from %@ failed", filePath);
        return;
    }
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"custom-events" data:data headers:@{@"Content-Type": @"application/json"} completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
            PREDLogDebug(@"Send custom events succeeded");
            [strongSelf->_persistence purgeFile:filePath];
            [strongSelf sendCustomEvents];
        } else {
            PREDLogError(@"send custom events error: %@", error);
        }
    }];
}

- (void)sendBreadcrumbs {
    NSString *filePath = [_persistence nextArchivedBreadcrumbPath];
    if (!filePath) {
        return;
    }
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data.length) {
        PREDLogError(@"get stored data from %@ failed", filePath);
        return;
    }
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"breadcrumbs" data:data headers:@{@"Content-Type": @"application/json"} completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
            PREDLogDebug(@"Send breadcrumbs succeeded");
            [strongSelf->_persistence purgeFile:filePath];
            [strongSelf sendBreadcrumbs];
        } else {
            PREDLogError(@"send breadcrumbs error: %@", error);
        }
    }];
}

@end
