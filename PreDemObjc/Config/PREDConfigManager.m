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

#define PREDConfigUserDefaultsKey   @"PREDConfigUserDefaultsKey"

NSString *kPREDConfigRefreshedNotification = @"com.qiniu.predem.config";
NSString *kPREDConfigRefreshedNotificationConfigKey = @"com.qiniu.predem.config";

@interface PREDConfigManager ()

@property (nonatomic, strong) NSDate *lastReportTime;

@end

@implementation PREDConfigManager {
    PREDChannel *_channel;
}

- (instancetype)initWithChannel:(PREDChannel *)channel {
    if (self = [super init]) {
        _channel = channel;
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
    NSDictionary *dic = [NSUserDefaults.standardUserDefaults objectForKey:PREDConfigUserDefaultsKey];
    if (dic && [dic respondsToSelector:@selector(objectForKey:)]) {
        defaultConfig = [PREDConfig configWithDic:dic];
    } else {
        defaultConfig = PREDConfig.defaultConfig;
    }
    
    PREDAppInfo *info = [[PREDAppInfo alloc] init];
    [_channel sinkAppInfo:info];
    return defaultConfig;
}

- (void)didBecomeActive:(NSNotification *)noty {
    if (self.lastReportTime && [[NSDate date] timeIntervalSinceDate:self.lastReportTime] >= 60 * 60 * 24) {
        [self getConfig];
    }
}

- (void)configRefreshed:(NSNotification *)noty {
    NSDictionary *dic = noty.userInfo[kPREDConfigRefreshedNotificationConfigKey];
    [NSUserDefaults.standardUserDefaults setObject:dic forKey:PREDConfigUserDefaultsKey];
    self.lastReportTime = [NSDate date];
}

@end
