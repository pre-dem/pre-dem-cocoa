//
//  PREDNetworkClient.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDNetworkClient.h"
#import "PREDLogger.h"
#import "PREDCredential.h"
#import "PREDManagerPrivate.h"
#import "PREDError.h"
#import "NSObject+Serialization.h"

static NSString* PRED_HTTPS_PREFIX = @"https://";
static NSString* PRED_HTTP_PREFIX = @"http://";

static NSString* pred_appendTime(NSString* url){
    NSString *format = [url rangeOfString:@"?"].location == NSNotFound ? @"%@?t=%lld" : @"%@&t=%lld";
    return [NSString stringWithFormat:format, url, (int64_t)[[NSDate date] timeIntervalSince1970]];
}

@implementation PREDNetworkClient

- (instancetype)initWithBaseURL:(NSURL *)baseURL {
    self = [super init];
    if ( self ) {
        _baseURL = baseURL;
        _operationQueue = [[NSOperationQueue alloc] init];
        _operationQueue.maxConcurrentOperationCount = 3;
    }
    return self;
}

- (void)getPath:(NSString *)path
     parameters:(NSDictionary *)params
     completion:(PREDNetworkCompletionBlock)completion {
    NSString* url =  [NSString stringWithFormat:@"%@%@", _baseURL, path];
    if (params.count) {
        url = [url stringByAppendingFormat:@"?%@", [self queryStringFromParameters:params withEncoding:NSUTF8StringEncoding]];
    }
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"GET"];
    [self sendRequest:request completion:completion];
}

- (void)postPath:(NSString *)path
      parameters:(NSObject *)params
      completion:(PREDNetworkCompletionBlock)completion {
    NSError *error;
    NSData *data = [params toJsonWithError:&error];
    if (error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(nil, nil, error);
        });
        return;
    }
    [self postPath:path data:data headers:@{@"Content-type": @"application/json"} completion:completion];
}

- (void) postPath:(NSString*) path
             data:(NSData *) data
          headers:(NSDictionary *)headers
       completion:(PREDNetworkCompletionBlock) completion {
    NSError *error;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:path relativeToURL:_baseURL]];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:data];
    
    if (error) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            completion(nil, nil, error);
        });
        return;
    }
    if (headers) {
        [headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
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
    [self.operationQueue addOperation:operation];
}

- (PREDHTTPOperation*)operationWithURLRequest:(NSURLRequest*) request
                                   completion:(PREDNetworkCompletionBlock) completion {
    PREDHTTPOperation *operation = [PREDHTTPOperation operationWithRequest:request];
    [operation setCompletion:completion];
    return operation;
}

- (NSString *)queryStringFromParameters:(NSDictionary *) params withEncoding:(NSStringEncoding) encoding {
    NSMutableString *queryString = [NSMutableString new];
    [params enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSString* value, BOOL *stop) {
        NSAssert([key isKindOfClass:[NSString class]], @"Query parameters can only be string-string pairs");
        NSAssert([value isKindOfClass:[NSString class]], @"Query parameters can only be string-string pairs");
        
        [queryString appendFormat:queryString.length ? @"&%@=%@" : @"%@=%@", key, value];
    }];
    return queryString;
}

- (void)authorizeRequest:(NSMutableURLRequest *)request {
    NSString *url = request.URL.absoluteString;
    url = pred_appendTime(url);
    NSString *domainPath;
    if ([url hasPrefix:PRED_HTTPS_PREFIX]) {
        domainPath = [url substringFromIndex:[PRED_HTTPS_PREFIX length]];
    } else if ([url hasPrefix:PRED_HTTP_PREFIX]){
        domainPath =  [url substringFromIndex:[PRED_HTTP_PREFIX length]];
    } else {
        domainPath = url;
    }
    NSString* auth = [PREDCredential authorize:domainPath appKey:[[PREDManager sharedPREDManager] appKey]];
    [request setValue:auth forHTTPHeaderField:@"Authorization"];
    [request setURL:[NSURL URLWithString:url]];
}

@end
