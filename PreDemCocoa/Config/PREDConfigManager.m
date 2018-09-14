//
//  PREDConfig.m
//  PreDemCocoa
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDConfigManager.h"

#define PREDConfigUserDefaultsKey   @"PREDConfigUserDefaultsKey"

NSString *kPREDConfigRefreshedNotification = @"com.qiniu.predem.config";
NSString *kPREDConfigRefreshedNotificationConfigKey = @"com.qiniu.predem.config";

@interface PREDConfigManager ()

@property(nonatomic, strong) NSDate *lastReportTime;

@end

@implementation PREDConfigManager {
    PREDPersistence *_persistence;
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence {
    if (self = [super init]) {
        _persistence = persistence;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(configRefreshed:) name:kPREDConfigRefreshedNotificationConfigKey object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (PREDConfig *)getConfig {
    PREDConfig *defaultConfig;
    // 优先获取保存在 UserDefaults 中的配置
    NSDictionary *dic = [NSUserDefaults.standardUserDefaults objectForKey:PREDConfigUserDefaultsKey];
    if (dic && [dic respondsToSelector:@selector(objectForKey:)]) {
        defaultConfig = [PREDConfig configWithDic:dic];
    } else {
        defaultConfig = PREDConfig.defaultConfig;
    }

    PREDAppInfo *info = [[PREDAppInfo alloc] init];
    [_persistence persistAppInfo:info];
    return defaultConfig;
}

- (void)didBecomeActive:(NSNotification *)noty {
    // 每天只获取一次
    if (self.lastReportTime && [[NSDate date] timeIntervalSinceDate:self.lastReportTime] >= 60 * 60 * 24) {
        [self getConfig];
    }
}

- (void)configRefreshed:(NSNotification *)noty {
    // 将获取到的配置保存在 UserDefaults 中
    NSDictionary *dic = noty.userInfo[kPREDConfigRefreshedNotificationConfigKey];
    [NSUserDefaults.standardUserDefaults setObject:dic forKey:PREDConfigUserDefaultsKey];
    self.lastReportTime = [NSDate date];
}

@end
