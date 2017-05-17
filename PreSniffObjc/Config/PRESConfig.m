//
//  PRESConfig.m
//  PreSniffSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESConfig.h"

@implementation PRESConfig

+ (PRESConfig *)defaultConfig {
    PRESConfig *config = [PRESConfig new];
    config.httpMonitorEnabled = YES;
    config.crashReportEnabled = YES;
    config.telemetryEnabled = YES;
    return config;
}

+ (instancetype)configWithDic:(NSDictionary *)dic {
    PRESConfig *config = [PRESConfig new];
    config.httpMonitorEnabled = [[dic objectForKey:@"http_monitor_enabled"] boolValue];
    config.crashReportEnabled = [[dic objectForKey:@"crash_report_enabled"] boolValue];
    config.telemetryEnabled = [[dic objectForKey:@"telemetry_enabled"] boolValue];
    return config;
}

@end
