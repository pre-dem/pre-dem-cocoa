//
//  PREDConfig.m
//  PreDemCocoa
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
  config.webviewEnabled = YES;
  config.isVip = NO;
  return config;
}

+ (instancetype)configWithDic:(NSDictionary *)dic {
  PREDConfig *config = [PREDConfig new];
  config.httpMonitorEnabled = [dic[@"http_monitor_enabled"] boolValue];
  config.crashReportEnabled = [dic[@"crash_report_enabled"] boolValue];
  config.lagMonitorEnabled = [dic[@"lag_monitor_enabled"] boolValue];
  config.webviewEnabled = [dic[@"webview_enabled"] boolValue];
  config.isVip = [dic[@"vip"] boolValue];
  return config;
}

@end
