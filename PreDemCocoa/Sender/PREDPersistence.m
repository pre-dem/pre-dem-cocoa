//
//  PREDPersistence.m
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import "PREDPersistence.h"
#import "PREDHelper.h"
#import "PREDError.h"
#import "PREDLogger.h"

#define PREDMaxCacheFileSize    512 * 1024  // 512KB
#define PREDMillisecondPerSecond        1000

@implementation PREDPersistence {
    NSString *_appInfoDir;
    NSString *_httpDir;
    NSString *_netDir;
    NSString *_customDir;
    NSString *_transactionsDir;
    NSFileManager *_fileManager;
    NSFileHandle *_appInfoFileHandle;
    dispatch_queue_t _appInfoQueue;
    NSFileHandle *_httpFileHandle;
    dispatch_queue_t _httpQueue;
    NSFileHandle *_netFileHandle;
    dispatch_queue_t _netQueue;
    NSFileHandle *_customFileHandle;
    dispatch_queue_t _customEventQueue;
    NSFileHandle *_transactionsFileHandle;
    dispatch_queue_t _transactionsQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        _fileManager = [NSFileManager defaultManager];

        _appInfoDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"appInfo"];
        _httpDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"http"];
        _netDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"net"];
        _customDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"custom"];
        _transactionsDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"transactions"];


        _appInfoQueue = dispatch_queue_create("predem_app_info", DISPATCH_QUEUE_SERIAL);
        _httpQueue = dispatch_queue_create("predem_http", DISPATCH_QUEUE_SERIAL);
        _netQueue = dispatch_queue_create("predem_net", DISPATCH_QUEUE_SERIAL);
        _customEventQueue = dispatch_queue_create("predem_custom_event", DISPATCH_QUEUE_SERIAL);
        _transactionsQueue = dispatch_queue_create("predem_transactions", DISPATCH_QUEUE_SERIAL);

        NSError *error;
        [_fileManager createDirectoryAtPath:_appInfoDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _appInfoDir);
        }
        [_fileManager createDirectoryAtPath:_httpDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _httpDir);
        }
        [_fileManager createDirectoryAtPath:_netDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _netDir);
        }
        [_fileManager createDirectoryAtPath:_customDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _customDir);
        }
        [_fileManager createDirectoryAtPath:_transactionsDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _transactionsDir);
        }
        PREDLogVerbose(@"cache directory:\n%@", PREDHelper.cacheDirectory);
    }
    return self;
}

- (void)persistAppInfo:(PREDAppInfo *)appInfo {
    dispatch_async(_appInfoQueue, ^{
        NSError *error;
        NSData *toSave = [appInfo serializeForSending:&error];
        if (error) {
            PREDLogError(@"jsonize app info error: %@", error);
            return;
        }

        _appInfoFileHandle = [self updateFileHandle:_appInfoFileHandle dir:_appInfoDir];
        if (!_appInfoFileHandle) {
            PREDLogError(@"no file handle drop app info data");
            return;
        }
        [_appInfoFileHandle writeData:toSave];
        [_appInfoFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    });
}

- (void)persistHttpMonitor:(PREDHTTPMonitorModel *)httpMonitor {
    dispatch_async(_httpQueue, ^{
        NSError *error;
        NSData *toSave = [httpMonitor serializeForSending:&error];
        if (error) {
            PREDLogError(@"jsonize http monitor error: %@", error);
            return;
        }

        _httpFileHandle = [self updateFileHandle:_httpFileHandle dir:_httpDir];
        if (!_httpFileHandle) {
            PREDLogError(@"no file handle drop http monitor data");
            return;
        }
        [_httpFileHandle writeData:toSave];
        [_httpFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    });
}

- (void)persistNetDiagResult:(PREDNetDiagResult *)netDiagResult {
    dispatch_async(_netQueue, ^{
        NSError *error;
        NSData *toSave = [netDiagResult serializeForSending:&error];
        if (error) {
            PREDLogError(@"jsonize net diag error: %@", error);
            return;
        }

        _netFileHandle = [self updateFileHandle:_netFileHandle dir:_netDir];
        if (!_netFileHandle) {
            PREDLogError(@"no file handle drop http monitor data");
            return;
        }
        [_netFileHandle writeData:toSave];
        [_netFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    });
}

- (void)persistCustomEvent:(PREDCustomEvent *)event {
    dispatch_async(_customEventQueue, ^{
        NSError *error;
        NSData *toSave = [event serializeForSending:&error];
        if (error) {
            PREDLogError(@"jsonize custom events error: %@", error);
            return;
        }

        _customFileHandle = [self updateFileHandle:_customFileHandle dir:_customDir];
        if (!_customFileHandle) {
            PREDLogError(@"no file handle drop custom data");
            return;
        }
        [_customFileHandle writeData:toSave];
        [_customFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    });
}

- (void)persistTransaction:(PREDTransaction *)transaction {
    dispatch_async(_transactionsQueue, ^{
        NSError *error;
        NSData *toSave = [transaction serializeForSending:&error];
        if (error) {
            PREDLogError(@"jsonize transaction events error: %@", error);
            return;
        }

        _transactionsFileHandle = [self updateFileHandle:_transactionsFileHandle dir:_transactionsDir];
        if (!_transactionsFileHandle) {
            PREDLogError(@"no file handle drop transaction data");
            return;
        }
        [_transactionsFileHandle writeData:toSave];
        [_transactionsFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    });
}

// no batch

- (NSString *)nextArchivedAppInfoPath {
    NSFileHandle *fileHanle = _appInfoFileHandle;
    NSString *path = [self nextArchivedPathForDir:_appInfoDir fileHandle:&fileHanle inQueue:_appInfoQueue];
    _appInfoFileHandle = fileHanle;
    return path;
}

- (NSString *)nextArchivedHttpMonitorPath {
    NSFileHandle *fileHanle = _httpFileHandle;
    NSString *path = [self nextArchivedPathForDir:_httpDir fileHandle:&fileHanle inQueue:_httpQueue];
    _httpFileHandle = fileHanle;
    return path;
}

- (NSString *)nextArchivedNetDiagPath {
    NSFileHandle *fileHanle = _netFileHandle;
    NSString *path = [self nextArchivedPathForDir:_netDir fileHandle:&fileHanle inQueue:_netQueue];
    _netFileHandle = fileHanle;
    return path;
}

// do not use this method in _customEventQueue which will cause dead lock
- (NSString *)nextArchivedCustomEventsPath {
    NSFileHandle *fileHanle = _customFileHandle;
    NSString *path = [self nextArchivedPathForDir:_customDir fileHandle:&fileHanle inQueue:_customEventQueue];
    _customFileHandle = fileHanle;
    return path;
}

- (NSString *)nextArchivedTransactionsPath {
    NSFileHandle *fileHanle = _transactionsFileHandle;
    NSString *path = [self nextArchivedPathForDir:_transactionsDir fileHandle:&fileHanle inQueue:_transactionsQueue];
    _transactionsFileHandle = fileHanle;
    return path;
}

- (NSString *)nextArchivedPathForDir:(NSString *)dir fileHandle:(NSFileHandle *__autoreleasing *)fileHandle inQueue:(dispatch_queue_t)queue {
    __block NSString *archivedPath;
    dispatch_sync(queue, ^{
        for (NSString *filePath in [_fileManager enumeratorAtPath:dir]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*\\.archive$"];
            if ([predicate evaluateWithObject:filePath]) {
                archivedPath = [NSString stringWithFormat:@"%@/%@", dir, filePath];
            }
        }
        // if no archived file found
        for (NSString *filePath in [_fileManager enumeratorAtPath:dir]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*$"];
            if ([predicate evaluateWithObject:filePath]) {
                if (*fileHandle) {
                    [*fileHandle closeFile];
                    *fileHandle = nil;
                }
                NSError *error;
                archivedPath = [NSString stringWithFormat:@"%@/%@.archive", dir, filePath];
                [_fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", dir, filePath] toPath:archivedPath error:&error];
                if (error) {
                    archivedPath = nil;
                    NSLog(@"archive file %@ fail", filePath);
                    continue;
                }
            }
        }
    });
    return archivedPath;
}

- (NSMutableDictionary *)getLogMeta:(NSString *)filePath error:(NSError **)error {
    NSMutableDictionary *dic = [self getStoredMeta:filePath error:error];
    if (!dic) {
        return nil;
    }
    NSString *content = dic[@"content"];
    if (!content) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"get meta content %@ error", filePath];
        }
        return nil;
    }

    NSMutableDictionary *contentDic = [NSJSONSerialization JSONObjectWithData:[content dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:error];
    if (!contentDic) {
        return nil;
    }
    NSString *logFileName = contentDic[@"log_key"];
    if (!logFileName) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"get log meta %@ error", logFileName];
        }
        return nil;
    }
    NSString *logFilePath = [NSString stringWithFormat:@"%@/%@/%@", PREDHelper.cacheDirectory, @"logfiles", logFileName];
    contentDic[@"log_key"] = logFilePath;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:logFilePath error:error];
    if (!attributes) {
        return nil;
    }
    contentDic[@"start_time"] = @((uint64_t) ([attributes fileCreationDate].timeIntervalSince1970 * PREDMillisecondPerSecond));
    contentDic[@"end_time"] = @((uint64_t) ([attributes fileModificationDate].timeIntervalSince1970 * PREDMillisecondPerSecond));
    NSData *contentData = [NSJSONSerialization dataWithJSONObject:contentDic options:0 error:error];
    if (!contentData) {
        return nil;
    }
    dic[@"content"] = [[NSString alloc] initWithData:contentData encoding:NSUTF8StringEncoding];
    return dic;
}

- (NSMutableDictionary *)getStoredMeta:(NSString *)filePath error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"read file %@ error", filePath];
        }
        return nil;
    }
    NSError *err;
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&err];
    if (error) {
        *error = err;
    }
    if (!err && ![dic respondsToSelector:@selector(valueForKey:)]) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"wrong json object type %@", NSStringFromClass(dic.class)];
        }
        return nil;
    }
    return dic;
}

- (void)purgeFile:(NSString *)filePath {
    NSError *error;
    [_fileManager removeItemAtPath:filePath error:&error];
    if (error) {
        PREDLogError(@"purge file %@ error %@", filePath, error);
    } else {
        PREDLogVerbose(@"purge file %@ succeeded", filePath);
    }
}

- (void)purgeAllAppInfo {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_appInfoDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _appInfoDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllHttpMonitor {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_httpDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _httpDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllNetDiag {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_netDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _netDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllCustom {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_customDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _customDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllTransactions {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_transactionsDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _transactionsDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllPersistence {
    [self purgeAllAppInfo];
    [self purgeAllHttpMonitor];
    [self purgeAllCustom];
    [self purgeAllNetDiag];
    [self purgeAllTransactions];
}

- (void)purgeFiles:(NSArray<NSString *> *)filePaths {
    __block NSError *error;
    [filePaths enumerateObjectsUsingBlock:^(NSString *_Nonnull filePath, NSUInteger idx, BOOL *_Nonnull stop) {
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }];
}

- (NSFileHandle *)updateFileHandle:(NSFileHandle *)oldFileHandle dir:(NSString *)dir {
    if (oldFileHandle) {
        if (oldFileHandle.offsetInFile <= PREDMaxCacheFileSize) {
            return oldFileHandle;
        } else {
            [oldFileHandle closeFile];
            oldFileHandle = nil;
        }
    }

    NSString *availableFile;
    for (NSString *filePath in [_fileManager enumeratorAtPath:dir]) {
        NSString *normalFilePattern = @"^[0-9]+\\.?[0-9]*$";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", normalFilePattern];
        if ([predicate evaluateWithObject:filePath]) {
            availableFile = [NSString stringWithFormat:@"%@/%@", dir, filePath];
            break;
        }
    }
    if (!availableFile) {
        availableFile = [NSString stringWithFormat:@"%@/%f", dir, [[NSDate date] timeIntervalSince1970]];
        BOOL success = [_fileManager createFileAtPath:availableFile contents:nil attributes:nil];
        if (!success) {
            PREDLogError(@"create file failed %@", availableFile);
            return nil;
        }
    }
    oldFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:availableFile];
    [oldFileHandle seekToEndOfFile];
    return oldFileHandle;
}

@end
