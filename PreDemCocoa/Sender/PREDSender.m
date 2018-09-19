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
  PREDNetworkClient *_appClient;
  PREDSenderInternal *_customSender;
  PREDSenderInternal *_transactionSender;
  NSUInteger _interval;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl {
  if (self = [super init]) {
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

    _interval = PREDSendInterval;
  }
  return self;
}

- (void)purgeAll {
  [_customSender purgeAll];
  [_transactionSender purgeAll];
}

- (void)sendAllSavedData {
  PREDLogVerbose(@"trying to send all saved messages");
  [self sendAppInfo:nil];

  [_customSender send:nil recursively:YES];

  [_transactionSender send:nil recursively:YES];
  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_interval * NSEC_PER_SEC)),
      dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self sendAllSavedData];
      });
}

- (void)sendAppInfo:(PREDNetworkCompletionBlock)completion {
  __weak typeof(self) wSelf = self;
  NSData *data = [[PREDAppInfo new] serializeForSending:nil];
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

- (void)persistCustomEvent:(PREDCustomEvent *)event {
  [_customSender persist:event];
}

- (void)persistTransaction:(PREDTransaction *)transaction {
  [_transactionSender persist:transaction];
}

- (NSUInteger)interval {
  return _interval;
}

- (void)setInterval:(NSUInteger)interval {
  if (interval < 30) {
    interval = 30;
  } else if (interval > 1800) {
    interval = 1800;
  }
  _interval = interval;
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

- (void)sendResponseWithData:(NSData *)data
                       error:(NSError *)error
                 recursively:(BOOL)recursively
                   operation:(PREDHTTPOperation *)operation
                  completion:(PREDNetworkCompletionBlock)completion {
  if (!error) {
    PREDLogDebug(@"Send succeeded %@", _path);
    [_persistence purgeAll];
    if (recursively) {
      [self send:completion recursively:recursively];
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
  [_networkClient
        postPath:_path
            data:data
         headers:[@{
           @"Content-Type" : @"application/json"
         } mutableCopy]
      completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        [self sendResponseWithData:data
                             error:error
                       recursively:recursively
                         operation:operation
                        completion:completion];
      }];
}

@end
