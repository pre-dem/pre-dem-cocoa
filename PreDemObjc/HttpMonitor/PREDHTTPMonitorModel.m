//
//  PREDHTTPMonitorModel.m
//  PreDemSDK
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDHTTPMonitorModel.h"
#import "PREDHelper.h"
#import <objc/runtime.h>

@implementation PREDHTTPMonitorModel

- (instancetype)init {
    if (self = [super init]) {
        self.platform = 1;
        self.appName = PREDHelper.appName;
        self.appBundleId = PREDHelper.appBundleId;
        self.osVersion = PREDHelper.osVersion;
        self.deviceModel = PREDHelper.deviceModel;
        self.deviceUUID = PREDHelper.appAnonID;
    }
    return self;
}

@end
