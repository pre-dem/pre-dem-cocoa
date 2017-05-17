//
//  PRESConfig.h
//  PreSniffSDK
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESConfig : NSObject

@property(nonatomic, strong, class, readonly) PRESConfig *defaultConfig;
@property(nonatomic, assign) BOOL httpMonitorEnabled;
@property(nonatomic, assign) BOOL crashReportEnabled;
@property(nonatomic, assign) BOOL telemetryEnabled;

+ (instancetype)configWithDic:(NSDictionary *)dic;

@end
