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

#define DNSPodsHost @"119.29.29.29"

@interface PRESURLProtocol ()
<
NSURLSessionDataDelegate
>

@property (nonatomic, strong) NSURLSessionDataTask *task;

@end

@implementation PRESURLProtocol

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
    if ([NSURLProtocol propertyForKey:@"PRESURLProtocol" inRequest:request] ) {
        return NO;
    }
    
    return YES;
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
    NSMutableURLRequest *mutableRequest = [request mutableCopy];
    [mutableRequest setValue:mutableRequest.URL.host forHTTPHeaderField:@"Host"];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PRESURLProtocol"
                     inRequest:mutableRequest];
    NSMutableArray *resolvers = [[NSMutableArray alloc] init];
    [resolvers addObject:[QNResolver systemResolver]];
    [resolvers addObject:[[QNResolver alloc] initWithAddress:DNSPodsHost]];
    QNDnsManager *dns = [[QNDnsManager alloc] init:resolvers networkInfo:[QNNetworkInfo normal]];
    NSURL *replacedURL = [dns queryAndReplaceWithIP:mutableRequest.URL];
    if ([request.URL.scheme isEqualToString:@"http"]) {
        mutableRequest.URL = replacedURL;
        return mutableRequest;
    } else {
        return request;
    }
}

- (void)startLoading {
    NSURLSessionConfiguration *sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:[NSOperationQueue new]];
    self.task = [session dataTaskWithRequest:self.request];
    [self.task resume];
}

- (void)stopLoading {
    [self.task cancel];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler {
    [self.client URLProtocol:self wasRedirectedToRequest:request redirectResponse:response];
    completionHandler(request);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask willCacheResponse:(NSCachedURLResponse *)proposedResponse completionHandler:(void (^)(NSCachedURLResponse * _Nullable))completionHandler {
    completionHandler(nil);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    [self.client URLProtocol:self didReceiveResponse:response cacheStoragePolicy:NSURLCacheStorageAllowed];
    completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
    [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (error) {
        [self.client URLProtocol:self didFailWithError:error];
    } else {
        [self.client URLProtocolDidFinishLoading:self];
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    [self.client URLProtocol:self didFailWithError:error];
}

@end
