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

@implementation PREDPersistence {
    NSString *_appInfoDir;
    NSString *_crashDir;
    NSString *_lagDir;
    NSString *_logDir;
    NSString *_httpDir;
    NSString *_netDir;
    NSString *_customDir;
    NSFileManager *_fileManager;
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
    NSError *error;
    NSData *data = [logMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize log meta error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
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

- (void)persistCustomEventWithName:(NSString *)eventName events:(NSArray<NSDictionary<NSString *, NSString *> *>*)events {
    NSError *error;
    NSData *toSave = [NSJSONSerialization dataWithJSONObject:@{@"eventName": eventName, @"events": events} options:0 error:&error];
    if (error) {
        PREDLogError(@"jsonize custom events error: %@", error);
    }
    NSString *fileName = [NSString stringWithFormat:@"%f-%u", [[NSDate date] timeIntervalSince1970], arc4random()];
    BOOL success = [toSave writeToFile:[NSString stringWithFormat:@"%@/%@", _customDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write custom events to file %@ failed", fileName);
    }
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
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _logDir, files[0]];
    }
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

- (NSString *)nextCustomEventsPath {
    NSArray *files = [_fileManager enumeratorAtPath:_customDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _customDir, files[0]];
    }
}

- (NSMutableDictionary *)getStoredMeta:(NSString *)filePath error:(NSError **)error {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"read file %@ error", filePath];
        return nil;
    }
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:error];
    if (!error && ![dic respondsToSelector:@selector(valueForKey:)]) {
        *error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"wrong json object type %@", NSStringFromClass(dic.class)];
        return nil;
    }
    return dic;
}

- (void)purgeFile:(NSString *)filePath {
    NSError *error;
    [_fileManager removeItemAtPath:filePath error:&error];
    if (error) {
        PREDLogError(@"purge crash meta file %@ error %@", filePath, error);
    }
}

- (void)purgeAllAppInfo {
    NSError *error;
    for (NSString *fileName in [_fileManager enumeratorAtPath:_appInfoDir]) {
        NSString *filePath = [NSString stringWithFormat:@"%@/%@", _appInfoDir, fileName];
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge crash meta file %@ error %@", filePath, error);
        }
    }
}
- (void)purgeFiles:(NSArray<NSString *> *)filePaths {
    __block NSError *error;
    [filePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
        [_fileManager removeItemAtPath:filePath error:&error];
        if (error) {
            PREDLogError(@"purge crash meta file %@ error %@", filePath, error);
        }
    }];
}

@end
