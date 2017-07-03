//
//  PREDConfig.m
//  PreDemSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDConfigManager.h"
#import "PREDLogger.h"
#import "PREDManagerPrivate.h"
#import "PREDHelper.h"

#define PREDConfigRetryInterval 300

@interface PREDConfigManager ()
<
NSURLSessionDelegate
>

@property (nonatomic, strong) NSDate *lastReportTime;
@property (nonatomic, copy) NSString *appKey;

@end

@implementation PREDConfigManager {
}

- (instancetype)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (PREDConfig *)getConfigWithAppKey:(NSString *)appKey {
    self.appKey = appKey;
    PREDConfig *defaultConfig;
    NSDictionary *dic = [NSUserDefaults.standardUserDefaults objectForKey:@"predem_app_config"];
    if (dic && [dic respondsToSelector:@selector(objectForKey:)]) {
        defaultConfig = [PREDConfig configWithDic:dic];
    } else {
        defaultConfig = PREDConfig.defaultConfig;
    }
    
    NSDictionary *info = @{
                           @"app_bundle_id": PREDHelper.appBundleId,
                           @"app_name": PREDHelper.appName,
                           @"app_version": PREDHelper.appVersion,
                           @"device_model": PREDHelper.deviceModel,
                           @"os_platform": PREDHelper.osPlatform,
                           @"os_version": PREDHelper.osVersion,
                           @"sdk_version": PREDHelper.sdkVersion,
                           @"sdk_id": PREDHelper.appAnonID,
                           @"device_id": @""
                           };
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@app-config/i", [[PREDManager sharedPREDManager] baseUrl]]]];
    request.HTTPMethod = @"POST";
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *err;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:info options:0 error:&err];
    if (err) {
        PREDLogError(@"sys info can not be jsonized");
    }
    [NSURLProtocol setProperty:@YES
                        forKey:@"PREDInternalRequest"
                     inRequest:request];
    
    __weak typeof(self) wSelf = self;
    [[[NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration
                                    delegate:self
                               delegateQueue:[NSOperationQueue new]]
      dataTaskWithRequest:request
      completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
          NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
          if (error || httpResponse.statusCode != 200) {
              PREDLogError(@"%@", error.localizedDescription);
              dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PREDConfigRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                  [self getConfigWithAppKey:appKey];
              });
          } else {
              __strong typeof(wSelf) strongSelf = wSelf;
              strongSelf.lastReportTime = [NSDate date];
              NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
              if ([dic respondsToSelector:@selector(objectForKey:)]) {
                  [NSUserDefaults.standardUserDefaults setObject:dic forKey:@"predem_app_config"];
                  PREDConfig *config = [PREDConfig configWithDic:dic];
                  [strongSelf.delegate configManager:strongSelf didReceivedConfig:config];
              } else {
                  PREDLogError(@"config received from server has a wrong type");
              }
          }
      }]
     resume];
    return defaultConfig;
}

- (void)didBecomeActive:(NSNotification *)note {
    if (self.lastReportTime && [[NSDate date] timeIntervalSinceDate:self.lastReportTime] >= 60 * 60 * 24) {
        [self getConfigWithAppKey:self.appKey];
    }
}

@end
