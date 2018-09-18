//
//  PREDManager.m
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PreDemCocoa.h"
#import "PREDError.h"
#import "PREDHelper.h"
#import "PREDLogger.h"
#import "PREDManagerPrivate.h"
#import "PREDSender.h"
#import "PREDTransactionPrivate.h"
#import "PREDVersion.h"

static NSString *app_id(NSString *appKey) {
  if (appKey.length >= PREDAppIdLength) {
    return [appKey substringToIndex:PREDAppIdLength];
  } else {
    return appKey;
  }
}

@implementation PREDManager {
  BOOL started;
  PREDConfigManager *configManager;
  PREDSender *sender;
}

#pragma mark - Public Class Methods

+ (void)startWithAppKey:(NSString *)appKey
          serviceDomain:(NSString *)serviceDomain {
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                 ^{
                   [[self sharedPREDManager] startWithAppKey:appKey
                                               serviceDomain:serviceDomain];
                 });
}

+ (PREDTransaction *)transactionStart:(NSString *)transactionName {
  uint64_t startTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
  PREDTransaction *transaction =
      [PREDTransaction transactionWithSender:[self sharedPREDManager]->sender];
  transaction.transaction_name = transactionName;
  transaction.start_time = startTime;
  return transaction;
}

+ (void)trackCustomEvent:(PREDCustomEvent *)event {
  if (!event) {
    PREDLogError(@"event should not be nil");
    return;
  }
  [[self sharedPREDManager] trackEvent:event];
}

- (void)trackEvent:(PREDCustomEvent *)event {
  [sender persistCustomEvent:event];
}

+ (BOOL)started {
  return [PREDManager sharedPREDManager]->started;
}

+ (NSString *)tag {
  return PREDHelper.tag;
}

+ (void)setTag:(NSString *)tag {
  PREDHelper.tag = tag;
}

+ (NSUInteger)updateInterval {
  return 24;
}

+ (void)setUpdateInterval:(NSUInteger)interval {
}

+ (NSString *)version {
  return [PREDVersion getSDKVersion];
}

+ (NSString *)build {
  return [PREDVersion getSDKBuild];
}

#pragma mark - Private Methods

+ (PREDManager *)sharedPREDManager {
  static PREDManager *sharedInstance = nil;
  static dispatch_once_t pred;

  dispatch_once(&pred, ^{
    sharedInstance = [[PREDManager alloc] init];
  });

  return sharedInstance;
}

- (void)startInternalWithAppKey:(NSString *)appKey
                  serviceDomain:(NSString *)serviceDomain {
  self.appKey = appKey;
  NSError *error;
  // 初始化 sender
  if (![self initSenderWithDomain:serviceDomain appKey:appKey error:&error]) {
    PREDLogError(@"%@", error);
    return;
  }

  // 进行其他功能模块的初始化
  [self initializeModules];

  // 注册观察者，接收通知
  [self registerObservers];

  // 开始循环发送数据
  [sender sendAllSavedData];

  started = YES;
}

- (void)startWithAppKey:(NSString *)appKey
          serviceDomain:(NSString *)serviceDomain {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self startInternalWithAppKey:appKey serviceDomain:serviceDomain];
  });
  return;
}

- (BOOL)initSenderWithDomain:(NSString *)aServerURL
                      appKey:(NSString *)appKey
                       error:(NSError **)error {
  if (!aServerURL.length) {
    if (error) {
      *error = [PREDError
          GenerateNSError:kPREDErrorCodeInvalidServiceDomain
              description:@"你必须指定 server domain ！！！！！！"];
    }
    return NO;
  }
  if (appKey.length < PREDAppIdLength) {
    if (error) {
      *error = [PREDError
          GenerateNSError:kPREDErrorCodeInvalidAppKey
              description:@"app key 的长度必须大于等于 %d！！！！！！",
                          PREDAppIdLength];
    }
    return NO;
  }
  if (![aServerURL hasPrefix:@"http://"] &&
      ![aServerURL hasPrefix:@"https://"]) {
    aServerURL = [NSString stringWithFormat:@"http://%@", aServerURL];
  }

  aServerURL =
      [NSString stringWithFormat:@"%@/v2/%@/", aServerURL, app_id(appKey)];

  NSURL *url = [NSURL URLWithString:aServerURL];

  if (!url) {
    if (error) {
      *error = [PREDError
          GenerateNSError:kPREDErrorCodeInvalidServiceDomain
              description:@"service domain 的结构不正确: %@ ！！！！！！",
                          aServerURL];
    }
    return NO;
  }

  sender = [[PREDSender alloc] initWithBaseUrl:url];
  return YES;
}

- (void)initializeModules {
  configManager = [[PREDConfigManager alloc] initWithSender:sender];

  // this process will get default config and then use it to initialize all
  // module, besides it will also retrieve config from the server and config
  // will refresh when done.
  [self setConfig:[configManager getConfig]];
}

- (void)setConfig:(PREDConfig *)config {
}

- (void)registerObservers {
  [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(configRefreshed:)
             name:kPREDConfigRefreshedNotification
           object:nil];
}

- (void)configRefreshed:(NSNotification *)noty {
  NSDictionary *dic = noty.userInfo[kPREDConfigRefreshedNotificationConfigKey];
  PREDConfig *config = [PREDConfig configWithDic:dic];
  [self setConfig:config];
}

+ (BOOL)isVip {
  return NO;
}

+ (PREDTransactionQueue *)defaultTransactionQueue {
  return [PREDTransactionQueue new];
}

/* 默认的自定义事件队列，传送事件类型数据到服务端
 */
+ (PREDEventQueue *)defaultCustomEventQueue {
  return [PREDEventQueue new];
}

@end
