//
//  PREDSender.h
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDNetworkClient.h"
#import "PREDPersistence.h"
#import <Foundation/Foundation.h>

@interface PREDSender : NSObject

- (instancetype)initWithPersistence:(PREDPersistence *)persistence
                            baseUrl:(NSURL *)baseUrl;

- (void)sendAllSavedData;

- (void)sendAppInfo:(PREDNetworkCompletionBlock)completion;

- (void)sendCustomEvents:(PREDNetworkCompletionBlock)completion
             recursively:(BOOL)recursively;

- (void)sendTransactions:(PREDNetworkCompletionBlock)completion
             recursively:(BOOL)recursively;

@end
