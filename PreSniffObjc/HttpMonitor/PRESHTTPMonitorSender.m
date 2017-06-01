//
//  PRESHTTPMonitorSender.m
//  PreSniffSDK
//
//  Created by WangSiyu on 28/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESHTTPMonitorSender.h"
#import "PRESGZIP.h"

#define PRESSendLogDefaultInterval  10
#define PRESMaxLogLenth            (1024 * 64)
#define PRESMaxLogIndex             100
#define PRESSendTimeOut             10

#define PRESErrorDomain             @"error.sdk.presniff"
#define PRESHTTPMonitorDomain       @"http://localhost:8080"
#define PRESHTTPMonitorReportPath   @"/v1/http_monitor"
#define PRESReadFileIndexKey        @"read_file_index"
#define PRESReadFilePositionKey     @"read_file_position"
#define PRESWriteFileIndexKey       @"write_file_index"
#define PRESWriteFilePosition       @"write_file_position"

static NSString * wrapString(NSString *st) {
    NSString *ret = st ? (st.length != 0 ? st : @"-") : @"-";
    return ret;
}

@interface PRESHTTPMonitorSender ()
<
NSURLSessionDelegate
>

@property (nonatomic, strong) NSString          *logDirPath;
@property (nonatomic, strong) NSString          *indexFilePath;
@property (nonatomic, assign) unsigned int      mReadFileIndex;
@property (nonatomic, assign) unsigned int      mReadFilePosition;
@property (nonatomic, assign) unsigned int      mWriteFileIndex;
@property (nonatomic, assign) unsigned int      mWriteFilePosition;
@property (nonatomic, strong) NSTimer           *sendTimer;
@property (nonatomic, strong) NSRecursiveLock   *indexFileIOLock;
@property (nonatomic, strong) NSRecursiveLock   *logFileIOLock;
@property (nonatomic, strong) NSFileHandle      *indexFileHandle;
@property (nonatomic, assign) BOOL              isSendingData;
@property (nonatomic, strong) NSURLSession      *urlSession;
@property (nonatomic, strong) NSString          *logPathToBeRemoved;

@end

@implementation PRESHTTPMonitorSender

+ (instancetype)sharedSender {
    static PRESHTTPMonitorSender *object = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        object = [[PRESHTTPMonitorSender alloc] init];
    });
    return object;
}

- (instancetype)init {
    if (self = [super init]) {
        _logDirPath = [NSString stringWithFormat:@"%@Presniff_SDK_Log", [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] objectAtIndex:0] absoluteString] substringFromIndex:7]];
        _indexFilePath = [NSString stringWithFormat:@"%@/index.json", _logDirPath];
        _mReadFileIndex = 1;
        _mReadFilePosition = 0;
        _mWriteFileIndex = 1;
        _mWriteFilePosition = 0;
        _indexFileIOLock = [NSRecursiveLock new];
        _logFileIOLock = [NSRecursiveLock new];
        NSURLSessionConfiguration *sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration;
        _urlSession = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    }
    return self;
}

/**
 * 上报数据结构
 ```
 {
 appName:            String  // 宿主 App 的名字。
 appBundleId:        String  // 宿主 App 的唯一标识号(包名)
 osVersion:          String  // 系统版本号
 deviceModel:        String  // 设备型号
 deviceUUID:         String  // 设备唯一识别号
 domain:             String  // 请求的 Domain Name
 path:               String  // 请求的 Path
 method:             String  // 请求使用的 HTTP 方法，如 POST 等
 hostIP:             String  // 实际发生请求的主机 IP 地址
 statusCode:         Int     // 服务器返回的 HTTP 状态码
 startTimestamp:     UInt64  // 请求开始时间戳，单位是 Unix ms
 responseTimeStamp:  UInt64  // 服务器返回 Response 的时间戳，单位是 Unix ms
 endTimestamp:       UInt64  // 请求结束时间戳，单位是 Unix ms
 DNSTime:            UInt    // 请求的 DNS 解析时间, 单位是 ms
 dataLength:         UInt    // 请求返回的 data 的总长度，单位是 byte
 networkErrorCode:   Int     // 请求发生网络错误时的错误码
 networkErrorMsg:    String  // 请求发生网络错误时的错误信息
 }
 ```
 */
- (void)addModel:(PRESHTTPMonitorModel *)model {
    NSArray *modelArray = @[
                            @(model.platform),
                            wrapString(model.appName),
                            wrapString(model.appBundleId),
                            wrapString(model.osVersion),
                            wrapString(model.deviceModel),
                            wrapString(model.deviceUUID),
                            wrapString(model.domain),
                            wrapString(model.path),
                            wrapString(model.method),
                            wrapString(model.hostIP),
                            @(model.statusCode),
                            @(model.startTimestamp),
                            @(model.responseTimeStamp),
                            @(model.endTimestamp),
                            @(model.DNSTime),
                            @(model.dataLength),
                            @(model.networkErrorCode),
                            wrapString(model.networkErrorMsg)
                            ];
    [self writeArray:modelArray];
}

- (void)setEnable:(BOOL)enable {
    _enable = enable;
    if (enable && !_sendTimer) {
        _sendTimer = [NSTimer timerWithTimeInterval:PRESSendLogDefaultInterval target:self selector:@selector(sendLog) userInfo:nil repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer: _sendTimer forMode:NSRunLoopCommonModes];
    } else if (!enable && _sendTimer) {
        [_sendTimer invalidate];
        _sendTimer = nil;
    }
}

- (NSError *)writeArray:(NSArray *)array {
    if (!_enable) {
        return nil;
    }
    __block NSString *toWrite;
    [array enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (0 == idx) {
            toWrite = [NSString stringWithFormat:@"%@", obj];
        }else if (idx == array.count - 1) {
            toWrite = [NSString stringWithFormat:@"%@\t%@\n", toWrite, obj];
        } else {
            toWrite = [NSString stringWithFormat:@"%@\t%@", toWrite, obj];
        }
    }];
    NSData *dataToWrite = [toWrite dataUsingEncoding:NSUTF8StringEncoding];
    
    BOOL isDir = NO, exist = NO;
    NSError *err;
    
    exist = [[NSFileManager defaultManager] fileExistsAtPath:_logDirPath isDirectory:&isDir];
    if (!(exist && isDir)) {
        [[NSFileManager defaultManager] createDirectoryAtPath:_logDirPath withIntermediateDirectories:NO attributes:nil error:&err];
    }
    if (err) {
        NSLog(@"log file create error: %@", err);
        return err;
    }
    exist = [[NSFileManager defaultManager] fileExistsAtPath:_indexFilePath isDirectory:&isDir];
    if (!(exist && !isDir)) {
        [[NSFileManager defaultManager] createFileAtPath:_indexFilePath contents:nil attributes:nil];
        err = [self updateIndexFile];
        if (err) {
            return err;
        }
    }
    err = [self parseIndexFile];
    if (err) {
        return err;
    }
    err = [self writeData:dataToWrite];
    return err;
}

- (NSError *)updateIndexFile {
    NSError *err = nil;
    NSDictionary *dic = @{PRESReadFileIndexKey: @(_mReadFileIndex),
                          PRESReadFilePositionKey: @(_mReadFilePosition),
                          PRESWriteFileIndexKey: @(_mWriteFileIndex),
                          PRESWriteFilePosition: @(_mWriteFilePosition)};
    NSData *indexData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:&err];
    if (err) {
        NSLog(@"create json for update index file error: %@", err);
        return err;
    }
    if (!_indexFileHandle) {
        _indexFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:_indexFilePath];
    }
    if (!_indexFileHandle) {
        err = [NSError errorWithDomain:PRESErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"create index file handle error for: %@", _indexFilePath]}];
        NSLog(@"%@", err);
        return err;
    }
    
    [_indexFileHandle seekToFileOffset:0];
    [_indexFileIOLock lock];
    [_indexFileHandle writeData:indexData];
    [_indexFileHandle truncateFileAtOffset:indexData.length];
    [_indexFileIOLock unlock];
    return nil;
}

- (NSError *)parseIndexFile {
    [_indexFileIOLock lock];
    NSData *indexData = [NSData dataWithContentsOfFile:_indexFilePath];
    NSError *err = nil;
    if (indexData != nil) {
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:indexData options:0 error:&err];
        if (err) {
            NSLog(@"error:parse data failed %@", err);
            [_indexFileIOLock unlock];
            return err;
        }
        if (!dic || ![dic respondsToSelector:@selector(objectForKey:)]) {
            NSLog(@"index file json is not valid dictionary object");
            [_indexFileIOLock unlock];
            return err;
        }
        _mReadFileIndex = (unsigned int)[[dic objectForKey:PRESReadFileIndexKey] unsignedIntegerValue];
        _mReadFilePosition = (unsigned int)[[dic objectForKey:PRESReadFilePositionKey] unsignedIntegerValue];
        _mWriteFileIndex = (unsigned int)[[dic objectForKey:PRESWriteFileIndexKey] unsignedIntegerValue];
        _mWriteFilePosition = (unsigned int)[[dic objectForKey:PRESWriteFilePosition] unsignedIntegerValue];
    }
    [_indexFileIOLock unlock];
    return nil;
}

- (NSError *)writeData:(NSData *)dataToWrite {
    BOOL isDir = NO, exist = NO;
    NSError *err;
    
    if (_mWriteFilePosition + dataToWrite.length > PRESMaxLogLenth) {
        if (_mWriteFileIndex == PRESMaxLogIndex) {
            _mWriteFileIndex = 1;
        } else {
            _mWriteFileIndex ++;
        }
        _mWriteFilePosition = 0;
    }
    
    NSString *logName = [NSString stringWithFormat:@"log.%u", _mWriteFileIndex];
    NSString *logPath = [NSString stringWithFormat:@"%@/%@", _logDirPath, logName];
    exist = [[NSFileManager defaultManager] fileExistsAtPath:logPath isDirectory:&isDir];
    if (!(exist && !isDir)) {
        BOOL success = [[NSFileManager defaultManager] createFileAtPath:logPath contents:nil attributes:nil];
        if (!success) {
            err = [NSError errorWithDomain:PRESErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"create http monior log file error for: %@", logPath]}];
            NSLog(@"%@", err);
            return err;
        }
    }
    NSFileHandle *logFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:logPath];
    if (!logFileHandle) {
        err = [NSError errorWithDomain:PRESErrorDomain code:-1 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"create http monior log file handle error for: %@", logPath]}];
        NSLog(@"%@", err);
        return err;
    }
    [logFileHandle seekToFileOffset:_mWriteFilePosition];
    // 如果更新 index 发生错误就丢弃这条日志，下次再重试
    _mWriteFilePosition += dataToWrite.length;
    err = [self updateIndexFile];
    if (err) {
        _mWriteFilePosition -= dataToWrite.length;
        return err;
    }
    [_logFileIOLock lock];
    [logFileHandle writeData:dataToWrite];
    [_logFileIOLock unlock];
    return nil;
}

- (void)sendLog {
    if (!_enable) {
        return;
    }
    if (_isSendingData) {
        return;
    }
    _isSendingData = YES;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        BOOL isDir = NO, exist = NO;
        NSError *err;
        
        err = [self parseIndexFile];
        if (err) {
            _isSendingData = NO;
            return;
        }
        NSString *logFilePath = [NSString stringWithFormat:@"%@/log.%u", _logDirPath, _mReadFileIndex];
        exist = [[NSFileManager defaultManager] fileExistsAtPath:logFilePath isDirectory:&isDir];
        if (!exist || isDir) {
            NSLog(@"log file path not exist");
            _isSendingData = NO;
            return;
        }
        NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:logFilePath];
        if (!handle) {
            NSLog(@"log file handle generate failed");
            _isSendingData = NO;
            return;
        }
        
        NSData *dataUncompressed;
        [handle seekToFileOffset:_mReadFilePosition];
        if (_mReadFileIndex == _mWriteFileIndex) {
            dataUncompressed = [handle readDataOfLength:(_mWriteFilePosition - _mReadFilePosition)];
            _logPathToBeRemoved = nil;
        } else {
            dataUncompressed = [handle readDataToEndOfFile];
            if (!dataUncompressed.length) {
                [[NSFileManager defaultManager] removeItemAtPath:logFilePath error:&err];
                if (err) {
                    NSLog(@"remove log file failed: %@", err);
                }
                // 删除失败依然需要将读取的位置切换到下个文件，不管之前的文件了
                if (_mReadFileIndex == PRESMaxLogIndex) {
                    _mReadFileIndex = 1;
                } else {
                    _mReadFileIndex ++;
                }
                _mReadFilePosition = 0;
                [self updateIndexFile];
                _isSendingData = NO;
                return;
            }
            _logPathToBeRemoved = logFilePath;
        }
        
        if (!dataUncompressed || !dataUncompressed.length) {
            _isSendingData = NO;
            return;
        }
        
        NSData *dataToSend = [dataUncompressed pres_gzippedData];
        if (!dataToSend || !dataToSend.length) {
            NSLog(@"compressed data is empty");
            _isSendingData = NO;
            return;
        }
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", PRESHTTPMonitorDomain, PRESHTTPMonitorReportPath]]];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = PRESSendTimeOut;
        request.HTTPBody = dataToSend;
        [request addValue:@"application/x-gzip" forHTTPHeaderField:@"Content-Type"];
        [request addValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        [NSURLProtocol setProperty:@YES
                            forKey:@"PRESInternalRequest"
                         inRequest:request];
        [[_urlSession dataTaskWithRequest:request] resume];
    });
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
    NSError *err;
    if (!error && response.statusCode == 201) {
        if (_logPathToBeRemoved) {
            [[NSFileManager defaultManager] removeItemAtPath:_logPathToBeRemoved error:&err];
            if (err) {
                NSLog(@"delete log file failed: %@", err);
            }
            if (_mReadFileIndex == PRESMaxLogIndex) {
                _mReadFileIndex = 1;
            } else {
                _mReadFileIndex ++;
            }
            _mReadFilePosition = 0;
        } else {
            _mReadFilePosition = _mWriteFilePosition;
        }
    } else {
        NSLog(@"log send failure, statusCode: %@, error: %@", [NSHTTPURLResponse localizedStringForStatusCode:((NSHTTPURLResponse *)response).statusCode], err);
    }
    [self updateIndexFile];
    _isSendingData = NO;
}


@end
