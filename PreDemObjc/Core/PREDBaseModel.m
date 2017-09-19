//
//  PREDBaseModel.m
//  Pods
//
//  Created by 王思宇 on 15/09/2017.
//
//

#import "PREDBaseModel.h"
#import "PREDHelper.h"
#import "PREDError.h"

@implementation PREDBaseModel

- (instancetype)init {
    if ([super init]) {
        _app_bundle_id = PREDHelper.appBundleId;
        _app_name = PREDHelper.appName;
        _app_version = PREDHelper.appVersion;
        _device_model = PREDHelper.deviceModel;
        _os_platform = PREDHelper.osPlatform;
        _os_version = PREDHelper.osVersion;
        _os_build = PREDHelper.osBuild;
        _sdk_version = PREDHelper.sdkVersion;
        _sdk_id = PREDHelper.UUID;
        _tag = PREDHelper.tag;
        _manufacturer = @"Apple";
    }
    return self;
}

@end
