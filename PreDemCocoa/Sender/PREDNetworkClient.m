//
//  PREDNetworkClient.m
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDNetworkClient.h"
#import "PREDLogger.h"
#import "PREDCredential.h"
#import "PREDManagerPrivate.h"
#import "PREDError.h"
#import "PREDHelper.h"

static NSString *PRED_HTTPS_PREFIX = @"https://";
static NSString *PRED_HTTP_PREFIX = @"http://";

static NSString *pred_appendTime(NSString *url) {
    NSString *format = [url rangeOfString:@"?"].location == NSNotFound ? @"%@?t=%lld" : @"%@&t=%lld";
    return [NSString stringWithFormat:format, url, (int64_t) [[NSDate date] timeIntervalSince1970]];
}

@implementation PREDNetworkClient {
    NSURL *_baseURL;

    NSOperationQueue *_operationQueue;
}

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
    self = [super init];
    if (self) {
        _baseURL = baseURL;
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 3;
    }
    return self;
}

- (void)postPath:(NSString *)path
            data:(NSData *)data
         headers:(NSMutableDictionary *)headers
      completion:(PREDNetworkCompletionBlock)completion {
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path relativeToURL:_baseURL]];
    [request setHTTPMethod:@"POST"];
    NSError *error;
    NSData *compressedData = [PREDHelper gzipData:data error:&error];
    if (!error) {
        headers[@"Content-Encoding"] = @"gzip";
        data = compressedData;
    } else {
        PREDLogWarning(@"compress data failed, using raw data for sending");
    }
    [request setHTTPBody:data];
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
            NSAssert([key isKindOfClass:[NSString class]], @"headers can only be string-string pairs");
            NSAssert([obj isKindOfClass:[NSString class]], @"headers can only be string-string pairs");
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    [self sendRequest:request completion:completion];
}

- (void)sendRequest:(NSMutableURLRequest *)request completion:(PREDNetworkCompletionBlock)completion {
    [NSURLProtocol setProperty:@YES
                        forKey:@"PREDInternalRequest"
                     inRequest:request];
    [self authorizeRequest:request];
    PREDHTTPOperation *operation = [self operationWithURLRequest:request
                                                      completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
                                                          if (operation.response.statusCode >= 400) {
                                                              error = [PREDError GenerateNSError:kPREDErrorCodeInternalError description:@"server returned an error status code: %d, body: %@", operation.response.statusCode, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
                                                          }
                                                          completion(operation, data, error);
                                                      }];
    [_operationQueue addOperation:operation];
}

- (PREDHTTPOperation *)operationWithURLRequest:(NSURLRequest *)request
                                    completion:(PREDNetworkCompletionBlock)completion {
    PREDHTTPOperation *operation = [PREDHTTPOperation operationWithRequest:request];
    [operation setCompletion:completion];
    return operation;
}

- (void)authorizeRequest:(NSMutableURLRequest *)request {
    NSString *url = request.URL.absoluteString;
    url = pred_appendTime(url);
    NSString *domainPath;
    if ([url hasPrefix:PRED_HTTPS_PREFIX]) {
        domainPath = [url substringFromIndex:[PRED_HTTPS_PREFIX length]];
    } else if ([url hasPrefix:PRED_HTTP_PREFIX]) {
        domainPath = [url substringFromIndex:[PRED_HTTP_PREFIX length]];
    } else {
        domainPath = url;
    }
    NSString *auth = [PREDCredential authorize:domainPath appKey:[[PREDManager sharedPREDManager] appKey]];
    [request setValue:auth forHTTPHeaderField:@"Authorization"];
    [request setURL:[NSURL URLWithString:url]];
}

@end
