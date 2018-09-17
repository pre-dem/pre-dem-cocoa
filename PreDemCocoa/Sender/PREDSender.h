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

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;

- (void)sendAllSavedData;

- (void)purgeAll;

- (void)sendAppInfo:(PREDNetworkCompletionBlock)completion;

- (void)sendCustomEvents:(PREDNetworkCompletionBlock)completion
             recursively:(BOOL)recursively;

- (void)sendTransactions:(PREDNetworkCompletionBlock)completion
             recursively:(BOOL)recursively;

- (void)persistAppInfo:(PREDAppInfo *)appInfo;

- (void)persistCustomEvent:(PREDCustomEvent *)event;

- (void)persistTransaction:(PREDTransaction *)transaction;

@end
