//
//  PREDNetworkClient.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PREDHTTPOperation.h" //needed for typedef

extern NSString * const kPREDNetworkClientBoundary;

@interface PREDNetworkClient : NSObject

@property (nonatomic, strong) NSURL *baseURL;

@property (nonatomic, strong) NSOperationQueue *operationQueue;

- (instancetype) initWithBaseURL:(NSURL*) baseURL;

- (NSMutableURLRequest *) requestWithMethod:(NSString*) method
                                       path:(NSString *) path
                                 parameters:(NSDictionary *) params;

- (PREDHTTPOperation*) operationWithURLRequest:(NSURLRequest*) request
                                    completion:(PREDNetworkCompletionBlock) completion;

- (void) getPath:(NSString*) path
      parameters:(NSDictionary *) params
      completion:(PREDNetworkCompletionBlock) completion;

- (void) postPath:(NSString*) path
       parameters:(NSDictionary *) params
       completion:(PREDNetworkCompletionBlock) completion;

- (void) postPath:(NSString*) path
             data:(NSData *) data
          headers:(NSDictionary *)headers
       completion:(PREDNetworkCompletionBlock) completion;

- (void) enqeueHTTPOperation:(PREDHTTPOperation *) operation;

- (NSUInteger) cancelOperationsWithPath:(NSString*) path
                                 method:(NSString*) method;

#pragma mark - Helpers

+ (NSData *)dataWithPostValue:(NSString *)value forKey:(NSString *)key boundary:(NSString *) boundary;

+ (NSData *)dataWithPostValue:(NSData *)value forKey:(NSString *)key contentType:(NSString *)contentType boundary:(NSString *) boundary filename:(NSString *)filename;

@end
