//
//  PREDPersistence.m
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import "PREDPersistence.h"
#import "PREDError.h"
#import "PREDHelper.h"
#import "PREDLogger.h"
#import "PREDTransaction.h"

#define PREDMaxCacheFileSize 512 * 1024 // 512KB
#define PREDMillisecondPerSecond 1000

@interface PREDPersistenceInternal : NSObject

- (void)run:(dispatch_block_t)block;
// 将收集到的相关数据序列化并持久化到本地
- (void)persist:(NSData *)data;

// 获取持久化在本地的各种数据文件地址
- (NSString *)nextArchivedPath;

// 清除缓存文件相关方法
- (void)purgeFile:(NSString *)filePath;

- (void)purgeFiles:(NSArray<NSString *> *)filePaths;

- (void)purgeAll;

- (instancetype)initWithPath:(NSString *)path queue:(NSString *)queue;

@end

@implementation PREDPersistence {
  PREDPersistenceInternal *_appInfo;
  PREDPersistenceInternal *_customEvent;
  PREDPersistenceInternal *_transaction;
}

- (instancetype)init {
  if (self = [super init]) {
    _appInfo =
        [[PREDPersistenceInternal alloc] initWithPath:@"appInfo"
                                                queue:@"predem_app_info"];
    _customEvent =
        [[PREDPersistenceInternal alloc] initWithPath:@"custom"
                                                queue:@"predem_custom_event"];
    _transaction =
        [[PREDPersistenceInternal alloc] initWithPath:@"transactions"
                                                queue:@"predem_transactions"];
    PREDLogVerbose(@"cache directory:\n%@", PREDHelper.cacheDirectory);
  }
  return self;
}

- (void)persistAppInfo:(PREDAppInfo *)appInfo {
  [_appInfo run:^{
    NSError *error;
    NSData *toSave = [appInfo serializeForSending:&error];
    if (error) {
      PREDLogError(@"jsonize app info error: %@", error);
      return;
    }

    [_appInfo persist:toSave];
  }];
}

- (void)persistCustomEvent:(PREDCustomEvent *)event {
  [_customEvent run:^{
    NSError *error;
    NSData *toSave = [event serializeForSending:&error];
    if (error) {
      PREDLogError(@"jsonize custom events error: %@", error);
      return;
    }

    [_customEvent persist:toSave];
  }];
}

- (void)persistTransaction:(PREDTransaction *)transaction {
  [_transaction run:^{
    NSError *error;
    NSData *toSave = [transaction serializeForSending:&error];
    if (error) {
      PREDLogError(@"jsonize transaction error: %@", error);
      return;
    }

    [_transaction persist:toSave];
  }];
}

- (void)purgeAllPersistence {
  [_appInfo purgeAll];
  [_customEvent purgeAll];
  [_transaction purgeAll];
}

- (NSString *)nextArchivedAppInfoPath {
  return [_appInfo nextArchivedPath];
}

- (NSString *)nextArchivedCustomEventsPath {
  return [_customEvent nextArchivedPath];
}

- (NSString *)nextArchivedTransactionsPath {
  return [_transaction nextArchivedPath];
}

- (void)purgeAllAppInfo {
  [_appInfo purgeAll];
}

- (void)purgeAllCustom {
  [_customEvent purgeAll];
}

- (void)purgeAllTransactions {
  [_transaction purgeAll];
}
@end

@implementation PREDPersistenceInternal {
  NSString *_dir;
  NSFileManager *_fileManager;
  NSFileHandle *_fileHandle;
  dispatch_queue_t _queue;
  NSString *_path;
}

- (instancetype)initWithPath:(NSString *)path queue:(NSString *)queue {
  if (self = [super init]) {
    _path = path;
    _fileManager = [NSFileManager defaultManager];
    _dir =
        [NSString stringWithFormat:@"%@/%@", PREDHelper.cacheDirectory, path];
    _queue = dispatch_queue_create(
        [queue cStringUsingEncoding:kCFStringEncodingUTF8],
        DISPATCH_QUEUE_SERIAL);

    NSError *error;
    [_fileManager createDirectoryAtPath:_dir
            withIntermediateDirectories:YES
                             attributes:nil
                                  error:&error];
    if (error) {
      PREDLogError(@"create dir %@ failed", _dir);
    }
  }
  return self;
}

- (void)run:(dispatch_block_t)block {
  dispatch_async(_queue, ^{
    block();
  });
}

- (void)persist:(NSData *)data {

  NSError *error;
  _fileHandle = [self updateFileHandle:_fileHandle dir:_dir];
  if (!_fileHandle) {
    PREDLogError(@"no file handle drop %@ data", _path);
    return;
  }
  [_fileHandle writeData:data];
  [_fileHandle writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
}

// no batch

- (NSString *)nextArchivedPath {
  NSFileHandle *fileHandle = _fileHandle;
  NSString *path =
      [self nextArchivedPathForDir:_dir fileHandle:&fileHandle inQueue:_queue];
  _fileHandle = fileHandle;
  return path;
}

- (NSString *)nextArchivedPathForDirRun:(NSString *)dir
                             fileHandle:
                                 (NSFileHandle *__autoreleasing *)fileHandle {
  NSString *archivedPath;
  for (NSString *filePath in [_fileManager enumeratorAtPath:dir]) {
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"SELF MATCHES %@",
                                         @"^[0-9]+\\.?[0-9]*\\.archive$"];
    if ([predicate evaluateWithObject:filePath]) {
      archivedPath = [NSString stringWithFormat:@"%@/%@", dir, filePath];
    }
  }
  // if no archived file found
  for (NSString *filePath in [_fileManager enumeratorAtPath:dir]) {
    NSPredicate *predicate = [NSPredicate
        predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*$"];
    if ([predicate evaluateWithObject:filePath]) {
      if (*fileHandle) {
        [*fileHandle closeFile];
        *fileHandle = nil;
      }
      NSError *error;
      archivedPath =
          [NSString stringWithFormat:@"%@/%@.archive", dir, filePath];
      [_fileManager
          moveItemAtPath:[NSString stringWithFormat:@"%@/%@", dir, filePath]
                  toPath:archivedPath
                   error:&error];
      if (error) {
        archivedPath = nil;
        NSLog(@"archive file %@ fail", filePath);
        continue;
      }
    }
  }
  return archivedPath;
}

- (NSString *)nextArchivedPathForDir:(NSString *)dir
                          fileHandle:(NSFileHandle *__autoreleasing *)fileHandle
                             inQueue:(dispatch_queue_t)queue {
  __block NSString *archivedPath;
  dispatch_sync(queue, ^{
    archivedPath = [self nextArchivedPathForDirRun:dir fileHandle:fileHandle];
  });
  return archivedPath;
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

- (void)purgeAll {
  NSError *error;
  for (NSString *fileName in [_fileManager enumeratorAtPath:_dir]) {
    NSString *filePath = [NSString stringWithFormat:@"%@/%@", _dir, fileName];
    [_fileManager removeItemAtPath:filePath error:&error];
    if (error) {
      PREDLogError(@"purge file %@ error %@", filePath, error);
    } else {
      PREDLogVerbose(@"purge file %@ succeeded", filePath);
    }
  }
}

- (void)purgeFiles:(NSArray<NSString *> *)filePaths {
  __block NSError *error;
  [filePaths enumerateObjectsUsingBlock:^(NSString *_Nonnull filePath,
                                          NSUInteger idx, BOOL *_Nonnull stop) {
    [_fileManager removeItemAtPath:filePath error:&error];
    if (error) {
      PREDLogError(@"purge file %@ error %@", filePath, error);
    } else {
      PREDLogVerbose(@"purge file %@ succeeded", filePath);
    }
  }];
}

- (NSFileHandle *)updateFileHandle:(NSFileHandle *)oldFileHandle
                               dir:(NSString *)dir {
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
    NSPredicate *predicate =
        [NSPredicate predicateWithFormat:@"SELF MATCHES %@", normalFilePattern];
    if ([predicate evaluateWithObject:filePath]) {
      availableFile = [NSString stringWithFormat:@"%@/%@", dir, filePath];
      break;
    }
  }
  if (!availableFile) {
    availableFile = [NSString
        stringWithFormat:@"%@/%f", dir, [[NSDate date] timeIntervalSince1970]];
    BOOL success = [_fileManager createFileAtPath:availableFile
                                         contents:nil
                                       attributes:nil];
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
