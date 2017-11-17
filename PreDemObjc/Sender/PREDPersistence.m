//
//  PREDPersistence.m
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import "PREDPersistence.h"
#import "PREDHelper.h"
#import "PREDLogger.h"
#import "NSObject+Serialization.h"
#import "PREDError.h"
#import "NSData+gzip.h"

#define PREDMaxCacheFileSize    512 * 1024  // 512KB
#define PREDMillisecondPerSecond        1000

@implementation PREDPersistence {
    NSString *_appInfoDir;
    NSString *_crashDir;
    NSString *_lagDir;
    NSString *_logDir;
    NSString *_httpDir;
    NSString *_netDir;
    NSString *_customDir;
    NSString *_breadcrumbDir;
    NSFileManager *_fileManager;
    NSFileHandle *_customFileHandle;
    dispatch_queue_t _customEventQueue;
    NSFileHandle *_breadcrumbFileHandle;
    dispatch_queue_t _breadcrumbQueue;
    PREDLogMeta *_lastLogMeta;
    NSString *_lastLogMetaPath;
}

- (instancetype)init {
    if (self = [super init]) {
        _fileManager = [NSFileManager defaultManager];
        _appInfoDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"appInfo"];
        _crashDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"crash"];
        _lagDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"lag"];
        _logDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"log"];
        _httpDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"http"];
        _netDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"net"];
        _customDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"custom"];
        _breadcrumbDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"breadcrumb"];
        _customEventQueue = dispatch_queue_create("predem_custom_event", DISPATCH_QUEUE_SERIAL);
        _breadcrumbQueue = dispatch_queue_create("predem_breadcrumb", DISPATCH_QUEUE_SERIAL);
        
        NSError *error;
        [_fileManager createDirectoryAtPath:_appInfoDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _appInfoDir);
        }
        [_fileManager createDirectoryAtPath:_crashDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _crashDir);
        }
        [_fileManager createDirectoryAtPath:_lagDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _lagDir);
        }
        [_fileManager createDirectoryAtPath:_logDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _logDir);
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
        [_fileManager createDirectoryAtPath:_breadcrumbDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            PREDLogError(@"create dir %@ failed", _customDir);
        }
        PREDLogVerbose(@"cache directory:\n%@", PREDHelper.cacheDirectory);
    }
    return self;
}

- (void)persistAppInfo:(PREDAppInfo *)appInfo {
    NSError *error;
    NSData *data = [appInfo toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize app info error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _appInfoDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write app info to file %@ failed", fileName);
    }
}

- (void)persistCrashMeta:(PREDCrashMeta *)crashMeta {
    NSError *error;
    NSData *data = [crashMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize crash meta error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _crashDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write crash meta to file %@ failed", fileName);
    }
}

- (void)persistLagMeta:(PREDLagMeta *)lagMeta {
    NSError *error;
    NSData *data = [lagMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize lag meta error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _lagDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write lag meta to file %@ failed", fileName);
    }
}

- (void)persistLogMeta:(PREDLogMeta *)logMeta {
    NSString *fileName;
    NSError *error;
    if (logMeta != _lastLogMeta) {
        fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
        _lastLogMetaPath = fileName;
        _lastLogMeta = logMeta;
    } else {
        fileName = _lastLogMetaPath;
    }
    NSData *data = [logMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize log meta error: %@", error);
        return;
    }
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _logDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write log meta to file %@ failed", fileName);
    }
}

- (void)persistHttpMonitor:(PREDHTTPMonitorModel *)httpMonitor {
    NSData *data = [[httpMonitor tabString] dataUsingEncoding:NSUTF8StringEncoding];
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _httpDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write http meta to file %@ failed", fileName);
    }
}

- (void)persistNetDiagResult:(PREDNetDiagResult *)netDiagResult {
    NSError *error;
    NSData *toSave = [netDiagResult toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize net diag result error: %@", error);
    }
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
    BOOL success = [toSave writeToFile:[NSString stringWithFormat:@"%@/%@", _netDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write net diag to file %@ failed", fileName);
    }
}

- (void)persistCustomEvent:(PREDCustomEvent *)event {
    dispatch_async(_customEventQueue, ^{
        NSError *error;
        NSData *toSave = [event toJsonWithError:&error];
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

- (void)persistBreadcrumb:(PREDBreadcrumb *)breadcrumb {
    dispatch_async(_breadcrumbQueue, ^{
        NSError *error;
        NSData *toSave = [breadcrumb toJsonWithError:&error];
        if (error) {
            PREDLogError(@"jsonize custom events error: %@", error);
            return;
        }
        
        _breadcrumbFileHandle = [self updateFileHandle:_breadcrumbFileHandle dir:_breadcrumbDir];
        if (!_breadcrumbFileHandle) {
            PREDLogError(@"no file handle drop custom data");
            return;
        }
        [_breadcrumbFileHandle writeData:toSave];
        [_breadcrumbFileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
    });
}

- (NSString *)nextAppInfoPath {
    NSArray *files = [_fileManager enumeratorAtPath:_appInfoDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _appInfoDir, files[0]];
    }
}

- (NSString *)nextCrashMetaPath {
    NSArray *files = [_fileManager enumeratorAtPath:_crashDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _crashDir, files[0]];
    }
}

- (NSString *)nextLagMetaPath {
    NSArray *files = [_fileManager enumeratorAtPath:_lagDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _lagDir, files[0]];
    }
}

- (NSString *)nextLogMetaPath {
    NSArray *files = [_fileManager enumeratorAtPath:_logDir].allObjects;
    __block NSString *nextMetaPath;
    [files enumerateObjectsUsingBlock:^(NSString *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![obj isEqualToString:_lastLogMetaPath]) {
            nextMetaPath = [NSString stringWithFormat:@"%@/%@", _logDir, obj];
            *stop = YES;
        }
    }];
    return nextMetaPath;
}

- (NSString *)nextHttpMonitorPath {
    NSArray *files = [_fileManager enumeratorAtPath:_httpDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _httpDir, files[0]];
    }
}

- (NSArray *)allHttpMonitorPaths {
    NSMutableArray *result = [NSMutableArray array];
    for (NSString *fileName in [_fileManager enumeratorAtPath:_httpDir]) {
        if (![fileName hasPrefix:@"."]) {
            [result addObject:[NSString stringWithFormat:@"%@/%@", _httpDir, fileName]];
        }
    }
    return result;
}

- (NSString *)nextNetDiagPath {
    NSArray *files = [_fileManager enumeratorAtPath:_netDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _netDir, files[0]];
    }
}

// do not use this method in _customEventQueue which will cause dead lock
- (NSString *)nextArchivedCustomEventsPath {
    __block NSString *archivedPath;
    dispatch_sync(_customEventQueue, ^{
        for (NSString *filePath in [_fileManager enumeratorAtPath:_customDir]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*\\.archive$"];
            if ([predicate evaluateWithObject:filePath]) {
                archivedPath = [NSString stringWithFormat:@"%@/%@", _customDir, filePath];
            }
        }
        // if no archived file found
        for (NSString *filePath in [_fileManager enumeratorAtPath:_customDir]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*$"];
            if ([predicate evaluateWithObject:filePath]) {
                if (_customFileHandle) {
                    [_customFileHandle closeFile];
                    _customFileHandle = nil;
                }
                NSError *error;
                archivedPath = [NSString stringWithFormat:@"%@/%@.archive", _customDir, filePath];
                [_fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", _customDir, filePath] toPath:archivedPath error:&error];
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

- (NSString *)nextArchivedBreadcrumbPath {
    __block NSString *archivedPath;
    dispatch_sync(_breadcrumbQueue, ^{
        for (NSString *filePath in [_fileManager enumeratorAtPath:_breadcrumbDir]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*\\.archive$"];
            if ([predicate evaluateWithObject:filePath]) {
                archivedPath = [NSString stringWithFormat:@"%@/%@", _breadcrumbDir, filePath];
            }
        }
        // if no archived file found
        for (NSString *filePath in [_fileManager enumeratorAtPath:_breadcrumbDir]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*$"];
            if ([predicate evaluateWithObject:filePath]) {
                if (_breadcrumbFileHandle) {
                    [_breadcrumbFileHandle closeFile];
                    _breadcrumbFileHandle = nil;
                }
                NSError *error;
                archivedPath = [NSString stringWithFormat:@"%@/%@.archive", _breadcrumbDir, filePath];
                [_fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", _breadcrumbDir, filePath] toPath:archivedPath error:&error];
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
    NSError *err;
    NSMutableDictionary *dic = [self getStoredMeta:filePath error:&err];
    if (err) {
        if (error) {
            *error = err;
        }
        return nil;
    }
    NSString *logFileName = dic[@"log_key"];
    if (!logFileName) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"get log meta %@ error", logFileName];
        }
        return nil;
    }
    NSString *logFilePath = [NSString stringWithFormat:@"%@/%@/%@", PREDHelper.cacheDirectory, @"logfiles", logFileName];
    dic[@"log_key"] = logFilePath;
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:logFilePath error:&err];
    if (err) {
        if (error) {
            *error = err;
        }
        return nil;
    }
    dic[@"start_time"] = @((uint64_t)([attributes fileCreationDate].timeIntervalSince1970 * PREDMillisecondPerSecond));
    dic[@"end_time"] = @((uint64_t)([attributes fileModificationDate].timeIntervalSince1970 * PREDMillisecondPerSecond));
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
        *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"wrong json object type %@", NSStringFromClass(dic.class)];
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

- (void)purgeAllCrashMeta {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_crashDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _crashDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllLagMeta {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_lagDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _lagDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge file %@ error %@", filePath, error);
        } else {
            PREDLogVerbose(@"purge file %@ succeeded", filePath);
        }
    }
}

- (void)purgeAllLogMeta {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_logDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _logDir, fileName];
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

- (void)purgeAllPersistence {
    [self purgeAllAppInfo];
    [self purgeAllLagMeta];
    [self purgeAllLogMeta];
    [self purgeAllHttpMonitor];
    [self purgeAllCustom];
    [self purgeAllCrashMeta];
    [self purgeAllNetDiag];
}

- (void)purgeFiles:(NSArray<NSString *> *)filePaths {
    __block NSError *error;
    [filePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
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
            availableFile = filePath;
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
