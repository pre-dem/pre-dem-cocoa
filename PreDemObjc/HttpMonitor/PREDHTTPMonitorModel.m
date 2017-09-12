//
//  PREDHTTPMonitorModel.m
//  PreDemObjc
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
        self.app_bundle_id = PREDHelper.appBundleId;
        self.app_name = PREDHelper.appName;
        self.app_version = PREDHelper.appVersion;
        self.device_model = PREDHelper.deviceModel;
        self.os_platform = PREDHelper.osPlatform;
        self.os_build = PREDHelper.osBuild;
        self.sdk_version = PREDHelper.sdkVersion;
        self.sdk_id = PREDHelper.UUID;
        self.tag = PREDHelper.tag;
        self.manufacturer = @"Apple";
    }
    return self;
}

@end
