//
//  PREDNetworkClient.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDHTTPOperation.h" //needed for typedef
#import <Foundation/Foundation.h>

@interface PREDNetworkClient : NSObject

- (instancetype)initWithBaseURL:(NSURL *)baseURL;

- (void)postPath:(NSString *)path
            data:(NSData *)data
         headers:(NSMutableDictionary *)headers
      completion:(PREDNetworkCompletionBlock)completion;

@end
