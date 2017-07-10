//
//  PREDConfig.m
//  PreDemObjc
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

@property (nonatomic, strong) NSDate *lastReportTime;
@property (nonatomic, copy) NSString *appKey;

@end

@implementation PREDConfigManager {
    PREDNetworkClient *_client;
}

- (instancetype)initWithNetClient:(PREDNetworkClient *)client {
    if (self = [super init]) {
        _client = client;
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
                           @"sdk_id": PREDHelper.UUID,
                           @"device_id": @""
                           };
    __weak typeof(self) wSelf = self;
    [_client postPath:@"app-config/i" parameters:info completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if (error || operation.response.statusCode != 200) {
            PREDLogError(@"%@", error.localizedDescription);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PREDConfigRetryInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [strongSelf getConfigWithAppKey:appKey];
            });
        } else {
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
    }];
    
    return defaultConfig;
}

- (void)didBecomeActive:(NSNotification *)note {
    if (self.lastReportTime && [[NSDate date] timeIntervalSinceDate:self.lastReportTime] >= 60 * 60 * 24) {
        [self getConfigWithAppKey:self.appKey];
    }
}

@end
