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

@implementation PREDPersistence {
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

- (void)persist:(id<PREDSerializeData>)data {
  dispatch_async(_queue, ^{
    NSError *error;
    NSData *toSave = [data serializeForSending:&error];
    if (error) {
      PREDLogError(@"jsonize transaction error: %@", error);
      return;
    }

    [self persistSave:toSave];
  });
}

- (void)persistSave:(NSData *)data {
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
