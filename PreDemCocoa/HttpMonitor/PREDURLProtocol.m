//
//  PREDURLProtocol.m
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDURLProtocol.h"
#import "PREDURLSessionSwizzler.h"
#import "PREDLogger.h"
#import "PREDHelper.h"

static PREDPersistence *_persistence;
static BOOL _started = NO;

static NSString *kHTTPMonitorModelPropertyKey = @"PREDHTTPMonitorModel";
static NSString *kInternalRequestPropertyKey = @"PREDInternalRequest";
static NSString *kTaskPropertyKey = @"PREDTask";

@interface PREDURLProtocol ()
        <
        NSURLSessionDataDelegate
        >
@end

@implementation PREDURLProtocol

+ (void)setPersistence:(PREDPersistence *)persistence {
    _persistence = persistence;
}

+ (void)setStarted:(BOOL)started {
    if (_started == started) {
        return;
    }
    _started = started;
    if (started) {
        PREDLogDebug(@"Starting HttpManager");
        // 可拦截 [NSURLSession defaultSession] 以及 UIWebView 相关的请求
        [NSURLProtocol registerClass:self.class];

        // 拦截自定义生成的 NSURLSession 的请求
        if (![PREDURLSessionSwizzler isSwizzle]) {
            [PREDURLSessionSwizzler loadSwizzler];
        }
    } else {
        PREDLogDebug(@"Terminating HttpManager");
        [NSURLProtocol unregisterClass:self.class];

        if ([PREDURLSessionSwizzler isSwizzle]) {
            [PREDURLSessionSwizzler unloadSwizzler];
        }
    }
}

+ (BOOL)started {
    return _started;
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    return ![NSURLProtocol propertyForKey:kInternalRequestPropertyKey inRequest:request] &&
            ([request.URL.scheme isEqualToString:@"http"] ||
                    [request.URL.scheme isEqualToString:@"https"]);
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    PREDHTTPMonitorModel *HTTPMonitorModel = [[PREDHTTPMonitorModel alloc] init];
    [NSURLProtocol setProperty:HTTPMonitorModel
                        forKey:kHTTPMonitorModelPropertyKey
                     inRequest:mutableRequest];
    [NSURLProtocol setProperty:@YES
                        forKey:kInternalRequestPropertyKey
                     inRequest:mutableRequest];

    if (request.URL.port) {
        HTTPMonitorModel.domain = [NSString stringWithFormat:@"%@:%@", HTTPMonitorModel.domain, request.URL.port];
    } else {
        HTTPMonitorModel.domain = request.URL.host;
    }
    // 统一根目录型 path 格式
    NSString *path = request.URL.path;
    if (path.length == 0) {
        path = @"/";
    }
    if (request.URL.query.length) {
        HTTPMonitorModel.path = [NSString stringWithFormat:@"%@?%@", path, request.URL.query];
    } else {
        HTTPMonitorModel.path = path;
    }
    HTTPMonitorModel.method = request.HTTPMethod;

    // 仅 http 可使用 ip 直连
    if ([request.URL.scheme isEqualToString:@"http"]) {
        NSTimeInterval dnsStartTime = [[NSDate date] timeIntervalSince1970];
        NSString *hostIP = [PREDHelper lookupHostIPAddressForURL:mutableRequest.URL];
        NSTimeInterval dnsEndTime = [[NSDate date] timeIntervalSince1970];
        if (!hostIP.length) {
            return mutableRequest;
        }
        // 判定解析出的 IP 格式是否正确
        NSError *err;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^[0-9]+\\.[0-9]+\\.[0-9]+" options:0 error:&err];
        NSAssert(err == nil, @"invalid regex %@", err);
        NSInteger number = [regex numberOfMatchesInString:hostIP options:0 range:NSMakeRange(0, [hostIP length])];
        if (number == 0) {
            return mutableRequest;
        }

        NSString *otherComponents = [mutableRequest.URL.absoluteString substringFromIndex:mutableRequest.URL.scheme.length + 3 + mutableRequest.URL.host.length];
        NSURL *replacedURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@%@", mutableRequest.URL.scheme, hostIP, otherComponents]];
        HTTPMonitorModel.dns_time = (NSUInteger) ((dnsEndTime - dnsStartTime) * 1000);
        mutableRequest.URL = replacedURL;
        HTTPMonitorModel.host_ip = replacedURL.host;
    }
    return mutableRequest;
}

- (void)startLoading {
    PREDHTTPMonitorModel *HTTPMonitorModel = [NSURLProtocol propertyForKey:kHTTPMonitorModelPropertyKey inRequest:self.request];
    HTTPMonitorModel.start_timestamp = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
    HTTPMonitorModel.end_timestamp = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
    HTTPMonitorModel.response_time_stamp = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
    NSURLSessionConfiguration *sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:self.request];
    [task resume];
    [NSURLProtocol setProperty:task forKey:kTaskPropertyKey inRequest:(NSMutableURLRequest *) self.request];
    [session finishTasksAndInvalidate];
}

- (void)stopLoading {
    NSURLSessionTask *task = [NSURLProtocol propertyForKey:kTaskPropertyKey inRequest:self.request];
    [task cancel];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse *_Nullable))completionHandler {
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    completionHandler(NSURLSessionResponseAllow);
    PREDHTTPMonitorModel *HTTPMonitorModel = [NSURLProtocol propertyForKey:kHTTPMonitorModelPropertyKey inRequest:self.request];
    HTTPMonitorModel.response_time_stamp = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
    HTTPMonitorModel.status_code = ((NSHTTPURLResponse *) response).statusCode;
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    PREDHTTPMonitorModel *HTTPMonitorModel = [NSURLProtocol propertyForKey:kHTTPMonitorModelPropertyKey inRequest:self.request];
    HTTPMonitorModel.end_timestamp = (UInt64) ([[NSDate date] timeIntervalSince1970] * 1000);
    HTTPMonitorModel.data_length += data.length;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    PREDHTTPMonitorModel *HTTPMonitorModel = [NSURLProtocol propertyForKey:kHTTPMonitorModelPropertyKey inRequest:self.request];
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        HTTPMonitorModel.network_error_code = error.code;
        HTTPMonitorModel.network_error_msg = error.localizedDescription;
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
    [_persistence persistHttpMonitor:HTTPMonitorModel];
}

@end
