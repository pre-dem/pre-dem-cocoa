//
//  PREDSender.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDSender.h"
#import "PREDConfigManager.h"
#import "PREDError.h"
#import "PREDLogger.h"
#import "PREDTransaction.h"

#define PREDSendInterval 30

@interface PREDSenderInternal : NSObject

- (instancetype)initWithPersistence:(PREDPersistence *)persistence
                            baseUrl:(NSURL *)baseUrl
                           postpath:(NSString *)path;

- (void)send:(PREDNetworkCompletionBlock)completion
 recursively:(BOOL)recursively;

- (void)purgeAll;

- (void)persist:(id<PREDSerializeData>)data;

@end

@implementation PREDSender {
  PREDPersistence *_appInfo;
  PREDNetworkClient *_appClient;
  PREDSenderInternal *_customSender;
  PREDSenderInternal *_transactionSender;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl {
  if (self = [super init]) {

    _appInfo = [[PREDPersistence alloc] initWithPath:@"appInfo"
                                               queue:@"predem_app_info"];
    _appClient = [[PREDNetworkClient alloc] initWithBaseURL:baseUrl];
    PREDPersistence *customEvent =
        [[PREDPersistence alloc] initWithPath:@"custom"
                                        queue:@"predem_custom_event"];
    PREDPersistence *transaction =
        [[PREDPersistence alloc] initWithPath:@"transactions"
                                        queue:@"predem_transactions"];

    _customSender =
        [[PREDSenderInternal alloc] initWithPersistence:customEvent
                                                baseUrl:baseUrl
                                               postpath:@"custom-events"];
    _transactionSender =
        [[PREDSenderInternal alloc] initWithPersistence:transaction
                                                baseUrl:baseUrl
                                               postpath:@"transactions"];
  }
  return self;
}

- (void)purgeAll {
  [_appInfo purgeAll];
  [_customSender purgeAll];
  [_transactionSender purgeAll];
}

- (void)sendAllSavedData {
  PREDLogVerbose(@"trying to send all saved messages");
  [self sendAppInfo:nil];

  [_customSender send:nil recursively:YES];

  [_transactionSender send:nil recursively:YES];
  dispatch_after(dispatch_time(DISPATCH_TIME_NOW,
                               (int64_t)(PREDSendInterval * NSEC_PER_SEC)),
                 dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   [self sendAllSavedData];
                 });
}

- (void)sendAppInfo:(PREDNetworkCompletionBlock)completion {
  NSString *filePath = [_appInfo nextArchivedPath];
  if (!filePath) {
    if (completion) {
      completion(nil, nil, nil);
    }
    return;
  }
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  if (!data) {
    PREDLogError(@"get stored data %@ error", filePath);
    if (completion) {
      completion(nil, nil,
                 [PREDError
                     GenerateNSError:kPREDErrorCodeUnknown
                         description:@"get stored data %@ error", filePath]);
    }
    return;
  }
  __weak typeof(self) wSelf = self;
  [_appClient
        postPath:@"app-config"
            data:data
         headers:[@{
           @"Content-Type" : @"application/json"
         } mutableCopy]
      completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error) {
          PREDLogError(@"get config failed: %@", error);
        } else {
          NSDictionary *dic =
              [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
          if ([dic respondsToSelector:@selector(objectForKey:)]) {
            PREDLogVerbose(@"got config:\n%@", dic);
            [[NSNotificationCenter defaultCenter]
                postNotificationName:kPREDConfigRefreshedNotification
                              object:self
                            userInfo:@{
                              kPREDConfigRefreshedNotificationConfigKey : dic
                            }];
          } else {
            PREDLogError(@"config received from server has a wrong type: %@",
                         dic);
          }
          [strongSelf->_appInfo purgeAll];
        }
        if (completion) {
          completion(operation, data, error);
        }
      }];
}

- (void)sendCustomEvents:(PREDNetworkCompletionBlock)completion
             recursively:(BOOL)recursively {
  [_customSender send:completion recursively:recursively];
}

- (void)sendTransactions:(PREDNetworkCompletionBlock)completion
             recursively:(BOOL)recursively {
  [_transactionSender send:completion recursively:recursively];
}

- (void)persistAppInfo:(PREDAppInfo *)appInfo {
  [_appInfo persist:appInfo];
}

- (void)persistCustomEvent:(PREDCustomEvent *)event {
  [_customSender persist:event];
}

- (void)persistTransaction:(PREDTransaction *)transaction {
  [_transactionSender persist:transaction];
}

@end

@implementation PREDSenderInternal {
  PREDPersistence *_persistence;
  PREDNetworkClient *_networkClient;
  NSString *_path;
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence
                            baseUrl:(NSURL *)baseUrl
                           postpath:(NSString *)path {
  if (self = [super init]) {
    _persistence = persistence;
    _networkClient = [[PREDNetworkClient alloc] initWithBaseURL:baseUrl];
    _path = path;
  }
  return self;
}

- (void)purgeAll {
  [_persistence purgeAll];
}

- (void)persist:(id<PREDSerializeData>)data {
  [_persistence persist:data];
}

- (void)send:(PREDNetworkCompletionBlock)completion
 recursively:(BOOL)recursively {
  NSString *filePath = [_persistence nextArchivedPath];
  if (!filePath) {
    if (completion) {
      completion(nil, nil, nil);
    }
    return;
  }
  NSData *data = [NSData dataWithContentsOfFile:filePath];
  if (!data || !data.length) {
    PREDLogError(@"get stored data from %@ failed", filePath);
    if (completion) {
      completion(nil, nil,
                 [PREDError
                     GenerateNSError:kPREDErrorCodeUnknown
                         description:@"get stored data %@ error", filePath]);
    }
    return;
  }
  __weak typeof(self) wSelf = self;
  [_networkClient
        postPath:_path
            data:data
         headers:[@{
           @"Content-Type" : @"application/json"
         } mutableCopy]
      completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (!error) {
          PREDLogDebug(@"Send succeeded %@", _path);
          [strongSelf->_persistence purgeAll];
          if (recursively) {
            [strongSelf send:completion recursively:recursively];
          } else {
            if (completion) {
              completion(operation, data, error);
            }
          }
        } else {
          PREDLogError(@"send %@ error: %@", _path, error);
          if (completion) {
            completion(operation, data, error);
          }
        }
      }];
}

@end
