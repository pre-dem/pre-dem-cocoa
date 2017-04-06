//
//  PRESURLProtocol.m
//  PreSniffSDK
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESURLProtocol.h"
#import <HappyDNS/HappyDNS.h>
#import "PRESURLSessionSwizzler.h"
#import "PRESHTTPMonitorModel.h"
#import "PRESHTTPMonitorSender.h"

#define DNSPodsHost @"119.29.29.29"

@interface PRESURLProtocol ()
<
NSURLSessionDataDelegate
>

@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSURLResponse *response;
@property (nonatomic, strong) PRESHTTPMonitorModel *HTTPMonitorModel;

@end

@implementation PRESURLProtocol

@synthesize HTTPMonitorModel;

+ (void)enableHTTPSniff {
    // 可拦截 [NSURLSession defaultSession] 以及 UIWebView 相关的请求
    [NSURLProtocol registerClass:self];
    
    // 拦截自定义生成的 NSURLSession 的请求
    if (![[PRESURLSessionSwizzler defaultSwizzler] isSwizzle]) {
        [[PRESURLSessionSwizzler defaultSwizzler] load];
    }
}

+ (void)disableHTTPSniff {
    [NSURLProtocol unregisterClass:self];
    if ([[PRESURLSessionSwizzler defaultSwizzler] isSwizzle]) {
        [[PRESURLSessionSwizzler defaultSwizzler] unload];
    }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
    if (![request.URL.scheme isEqualToString:@"http"] &&
        ![request.URL.scheme isEqualToString:@"https"]) {
        return NO;
    }
    
    // SDK主动发送的数据
    if ([NSURLProtocol propertyForKey:@"PRESInternalRequest" inRequest:request] ) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PRESInternalRequest"
                     inRequest:mutableRequest];
    [NSURLProtocol setProperty:mutableRequest.URL.absoluteString
                        forKey:@"PRESOriginalURL"
                     inRequest:mutableRequest];
    if ([request.URL.scheme isEqualToString:@"http"]) {
        NSMutableArray *resolvers = [[NSMutableArray alloc] init];
        [resolvers addObject:[QNResolver systemResolver]];
        [resolvers addObject:[[QNResolver alloc] initWithAddress:DNSPodsHost]];
        QNDnsManager *dns = [[QNDnsManager alloc] init:resolvers networkInfo:[QNNetworkInfo normal]];
        NSTimeInterval dnsStartTime = [[NSDate date] timeIntervalSince1970];
        NSURL *replacedURL = [dns queryAndReplaceWithIP:mutableRequest.URL];
        NSTimeInterval dnsEndTime = [[NSDate date] timeIntervalSince1970];
        [NSURLProtocol setProperty:[NSString stringWithFormat:@"%u",
                                    (NSUInteger)((dnsEndTime - dnsStartTime)*1000)]
                            forKey:@"PRESDNSTime"
                         inRequest:mutableRequest];
        [NSURLProtocol setProperty:replacedURL.host
                            forKey:@"PRESHostIP"
                         inRequest:mutableRequest];
        [mutableRequest setValue:mutableRequest.URL.host forHTTPHeaderField:@"Host"];
        mutableRequest.URL = replacedURL;
    }
    return mutableRequest;
}

- (void)startLoading {
    NSURLSessionConfiguration *sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    self.task = [session dataTaskWithRequest:self.request];
    [self.task resume];
    
    HTTPMonitorModel = [[PRESHTTPMonitorModel alloc] init];
    [HTTPMonitorModel updateModelWithRequest:self.request];
    HTTPMonitorModel.startTimestampViaMin = ((int)[[NSDate date] timeIntervalSince1970]) / 60 * 60;
    HTTPMonitorModel.startTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    
    HTTPMonitorModel.responseTimeStamp = 0;
    HTTPMonitorModel.responseDataLength = 0;
    
    NSTimeInterval myId = [[NSDate date] timeIntervalSince1970];
    double randomNum = ((double)(arc4random() % 100))/10000;
    HTTPMonitorModel.myId = myId + randomNum;
}

- (void)stopLoading {
    [self.task cancel];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    if (response != nil) {
        self.response = response;
    }
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
    HTTPMonitorModel.responseTimeStamp = [[NSDate date] timeIntervalSince1970] * 1000;
    [HTTPMonitorModel updateModelWithResponse:(NSHTTPURLResponse *)response];
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
    HTTPMonitorModel.endTimestamp = [[NSDate date] timeIntervalSince1970] * 1000;
    HTTPMonitorModel.responseDataLength += data.length;
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
        HTTPMonitorModel.errorCode = error.code;
        HTTPMonitorModel.errorMsg = error.localizedDescription;
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
    [[PRESHTTPMonitorSender sharedSender] addModel:HTTPMonitorModel];
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
