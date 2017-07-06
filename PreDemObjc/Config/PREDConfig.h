//
//  PREDConfig.h
//  Pods
//
//  Created by WangSiyu on 10/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PREDConfig : NSObject

@property(nonatomic, strong, class, readonly) PREDConfig *defaultConfig;
@property(nonatomic, assign) BOOL httpMonitorEnabled;
@property(nonatomic, assign) BOOL crashReportEnabled;

+ (instancetype)configWithDic:(NSDictionary *)dic;

@end
