//
//  PREDSender.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDSender.h"
#import "PREDHelper.h"
#import "PREDLogger.h"
#import "QiniuSDK.h"
#import "PREDConfigManager.h"

@implementation PREDSender {
    PREDPersistence *_persistence;
    PREDNetworkClient *_networkClient;
    QNUploadManager *_uploadManager;
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence baseUrl:(NSURL *)baseUrl {
    if (self = [super init]) {
        _persistence = persistence;
        _uploadManager = [[QNUploadManager alloc] init];
        _networkClient = [[PREDNetworkClient alloc] initWithBaseURL:baseUrl];
        [self registerObservers];
    }
    return self;
}

- (void)registerObservers {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sendSavedData) name:kPREDDataPersistedNotification object:nil];
}

- (void)sendSavedData {
    [self sendCrashData];
    [self sendLagData];
    [self sendLogData];
    [self sendHttpMonitor];
    [self sendNetDiag];
}

- (void)sendAppInfo {
    NSString *filePath = [_persistence nextAppInfoPath];
    NSMutableDictionary *meta = [_persistence parseFile:filePath];
    [_networkClient postPath:@"app-config/i" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        if (error) {
            PREDLogError(@"get config failed: %@", error);
        } else {
            NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            if ([dic respondsToSelector:@selector(objectForKey:)]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kPREDConfigRefreshedNotification object:self userInfo:@{kPREDConfigRefreshedNotificationConfigKey: dic}];
            } else {
                PREDLogError(@"config received from server has a wrong type");
            }
        }
    }];
    
}

- (void)sendCrashData {
    NSString *filePath = [_persistence nextCrashMetaPath];
    NSMutableDictionary *meta = [_persistence parseFile:filePath];
    NSString *logString = meta[@"crash_log_key"];
    NSString *md5 = [PREDHelper MD5:logString];
    NSDictionary *param = @{@"md5": md5};
    __weak typeof(self) wSelf = self;
    [_networkClient getPath:@"crash-report-token/i" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get crash token error: %@", error);
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
            NSString *key = [dic valueForKey:@"key"];
            NSString *token = [dic valueForKey:@"token"];
            meta[@"crash_log_key"] = key;
            [strongSelf->_uploadManager
             putData:[logString dataUsingEncoding:NSUTF8StringEncoding]
             key:key
             token: token
             complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                 if (resp) {
                     PREDLogDebug(@"Sending crash reports");
                     [strongSelf->_networkClient postPath:@"crashes/i" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                         __strong typeof (wSelf) strongSelf = wSelf;
                         if (!error) {
                             [strongSelf->_persistence purgeFile:filePath];
                             [strongSelf sendCrashData];
                         } else {
                             PREDLogError(@"upload crash meta fail: %@", error);
                         }
                     }];
                 } else {
                     PREDLogError(@"upload log fail: %@", info.error);
                     return;
                 }
             }
             option:nil];
        }
    }];
}

- (void)sendLagData {
    NSString *filePath = [_persistence nextLagMetaPath];
    NSMutableDictionary *meta = [_persistence parseFile:filePath];
    NSString *logString = meta[@"lag_log_key"];
    NSString *md5 = [PREDHelper MD5:logString];
    NSDictionary *param = @{@"md5": md5};
    __weak typeof(self) wSelf = self;
    [_networkClient getPath:@"lag-report-token/i" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get lag token error: %@", error);
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
            NSString *key = [dic valueForKey:@"key"];
            NSString *token = [dic valueForKey:@"token"];
            meta[@"lag_log_key"] = key;
            [strongSelf->_uploadManager
             putData:[logString dataUsingEncoding:NSUTF8StringEncoding]
             key:key
             token: token
             complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                 if (resp) {
                     PREDLogDebug(@"Sending lag reports");
                     [strongSelf->_networkClient postPath:@"lag-monitor/i" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                         __strong typeof (wSelf) strongSelf = wSelf;
                         if (!error) {
                             [strongSelf->_persistence purgeFile:filePath];
                             [strongSelf sendLagData];
                         } else {
                             PREDLogError(@"upload lag meta fail: %@", error);
                         }
                     }];
                 } else {
                     PREDLogError(@"upload log fail: %@", info.error);
                     return;
                 }
             }
             option:nil];
        }
    }];
}

- (void)sendLogData {
    NSString *filePath = [_persistence nextLogMetaPath];
    NSMutableDictionary *meta = [_persistence parseFile:filePath];
    NSString *logFilePath = meta[@"log_key"];
    NSData *logData = [NSData dataWithContentsOfFile:logFilePath];
    NSString *md5 = [PREDHelper MD5ForData:logData];
    NSDictionary *param = @{@"md5": md5};
    __weak typeof(self) wSelf = self;
    [_networkClient getPath:@"log-capture-token/i" parameters:param completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
            PREDLogError(@"get log token error: %@", error);
            return;
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (!error && [dic respondsToSelector:@selector(valueForKey:)] && [dic valueForKey:@"key"] && [dic valueForKey:@"token"]) {
            NSString *key = [dic valueForKey:@"key"];
            NSString *token = [dic valueForKey:@"token"];
            meta[@"log_key"] = key;
            [strongSelf->_uploadManager
             putData:logData
             key:key
             token: token
             complete:^(QNResponseInfo *info, NSString *key, NSDictionary *resp) {
                 __strong typeof(wSelf) strongSelf = wSelf;
                 if (resp) {
                     PREDLogDebug(@"Sending log reports");
                     [strongSelf->_networkClient postPath:@"log-capture/i" parameters:meta completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                         __strong typeof (wSelf) strongSelf = wSelf;
                         if (!error) {
                             [strongSelf->_persistence purgeFile:filePath];
                             [strongSelf->_persistence purgeFile:logFilePath];
                             [strongSelf sendLagData];
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
        }
    }];
}

- (void)sendHttpMonitor {
    NSString *filePath = [_persistence nextHttpMonitorPath];
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"http-stats/i" parameters:[NSData dataWithContentsOfFile:filePath] completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
            [strongSelf->_persistence purgeFile:filePath];
            [strongSelf sendHttpMonitor];
        } else {
            PREDLogError(@"upload http monitor fail: %@", error);
        }
    }];
}

- (void)sendNetDiag {
    NSString *filePath = [_persistence nextNetDiagPath];
    __weak typeof(self) wSelf = self;
    [_networkClient postPath:@"net-diags/i" parameters:[NSData dataWithContentsOfFile:filePath] completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
            [strongSelf->_persistence purgeFile:filePath];
            [strongSelf sendNetDiag];
        } else {
            PREDLogError(@"send net diag error: %@", error);
        }
    }];
}


@end
