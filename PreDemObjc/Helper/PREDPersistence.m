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

NSString *kPREDDataPersistedNotification = @"com.qiniu.predem.persist";

@implementation PREDPersistence {
    NSString *_crashDir;
    NSString *_lagDir;
    NSString *_logDir;
    NSString *_httpDir;
    NSString *_netDir;
    NSFileManager *_fileManager;
}

- (instancetype)init {
    if (self = [super init]) {
        _fileManager = [NSFileManager defaultManager];
        _crashDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"crash"];
        _lagDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"lag"];
        _logDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"log"];
        _httpDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"http"];
        _netDir = [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, @"net"];

        NSError *error;
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
            PREDLogError(@"create dir %@ failed", _httpDir);
        }
    }
    return self;
}

- (void)persistCrashMeta:(PREDCrashMeta *)crashMeta {
    NSError *error;
    NSData *data = [crashMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize crash meta error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _crashDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write crash meta to file %@ failed", fileName);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPREDDataPersistedNotification object:nil];
    }
}

- (void)persistLagMeta:(PREDLagMeta *)lagMeta {
    NSError *error;
    NSData *data = [lagMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize lag meta error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _lagDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write lag meta to file %@ failed", fileName);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPREDDataPersistedNotification object:nil];
    }
}

- (void)persistLogMeta:(PREDLogMeta *)logMeta {
    NSError *error;
    NSData *data = [logMeta toJsonWithError:&error];
    if (error) {
        PREDLogError(@"jsonize log meta error: %@", error);
        return;
    }
    NSString *fileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    BOOL success = [data writeToFile:[NSString stringWithFormat:@"%@/%@", _logDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write log meta to file %@ failed", fileName);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPREDDataPersistedNotification object:nil];
    }
}

- (void)persistHttpMonitors:(NSArray<PREDHTTPMonitorModel *> *)httpMonitors {
    __block NSString *toSave;
    [httpMonitors enumerateObjectsUsingBlock:^(PREDHTTPMonitorModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == 0) {
            toSave = [obj tabString];
        } else {
            toSave = [NSString stringWithFormat:@"%@\n%@", toSave, [obj tabString]];
        }
    }];
    NSString *fileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    BOOL success = [[toSave dataUsingEncoding:NSUTF8StringEncoding] writeToFile:[NSString stringWithFormat:@"%@/%@", _httpDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write http monitor to file %@ failed", fileName);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPREDDataPersistedNotification object:nil];
    }
}

- (void)persistNetDiagResults:(NSArray<PREDNetDiagResult *> *)netDiagResults {
    NSError *error;
    NSData *toSave = [netDiagResults toJsonWithError:&error];
    if (error) {
        PREDLogError(@"parse net diag result error: %@", error);
    }
    NSString *fileName = [NSString stringWithFormat:@"%f", [[NSDate date] timeIntervalSince1970]];
    BOOL success = [toSave writeToFile:[NSString stringWithFormat:@"%@/%@", _netDir, fileName] atomically:NO];
    if (!success) {
        PREDLogError(@"write net diag to file %@ failed", fileName);
    } else {
        [[NSNotificationCenter defaultCenter] postNotificationName:kPREDDataPersistedNotification object:nil];
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

- (NSString *)nextNetDiagPath {
    NSArray *files = [_fileManager enumeratorAtPath:_netDir].allObjects;
    if (files.count == 0) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@/%@", _netDir, files[0]];
    }
}

- (NSMutableDictionary *)parseFile:(NSString *)filePath {
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        PREDLogError(@"read crash meta file %@ error", filePath);
        return nil;
    }
    NSMutableDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        PREDLogError(@"read crash meta file %@ error %@", filePath, error);
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

@end
