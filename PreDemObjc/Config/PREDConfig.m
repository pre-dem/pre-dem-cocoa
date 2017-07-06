//
//  PREDConfig.m
//  PreDemObjc
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDConfig.h"

@implementation PREDConfig

+ (PREDConfig *)defaultConfig {
    PREDConfig *config = [PREDConfig new];
    config.httpMonitorEnabled = YES;
    config.crashReportEnabled = YES;
    config.lagMonitorEnabled = YES;
    return config;
}

+ (instancetype)configWithDic:(NSDictionary *)dic {
    PREDConfig *config = [PREDConfig new];
    config.httpMonitorEnabled = [[dic objectForKey:@"http_monitor_enabled"] boolValue];
    config.crashReportEnabled = [[dic objectForKey:@"crash_report_enabled"] boolValue];
    config.lagMonitorEnabled = [[dic objectForKey:@"lag_monitor_enabled"] boolValue];
    return config;
}

@end
