//
//  PREDHTTPMonitorModel.m
//  PreDemSDK
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDHTTPMonitorModel.h"
#import "PREDUtilities.h"
#import <objc/runtime.h>

@implementation PREDHTTPMonitorModel

- (instancetype)init {
    if (self = [super init]) {
        self.platform = 1;
        self.appName = [PREDUtilities getAppName];
        self.appBundleId = [PREDUtilities getAppBundleId];
        self.osVersion = [PREDUtilities getOsVersion];
        self.deviceModel = [PREDUtilities getDeviceModel];
        self.deviceUUID = [PREDUtilities getDeviceUUID];
    }
    return self;
}

@end
