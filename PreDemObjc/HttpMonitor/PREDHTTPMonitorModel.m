//
//  PREDHTTPMonitorself.m
//  PreDemObjc
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDHTTPMonitorModel.h"
#import "PREDHelper.h"
#import <objc/runtime.h>

static NSString * wrapString(NSString *st) {
    NSString *ret = st ? (st.length != 0 ? st : @"-") : @"-";
    return ret;
}

@implementation PREDHTTPMonitorModel

- (NSString *)tabString {
    NSArray *modelArray = @[
                            wrapString(self.app_bundle_id),
                            wrapString(self.app_name),
                            wrapString(self.app_version),
                            wrapString(self.device_model),
                            wrapString(self.os_platform),
                            wrapString(self.os_version),
                            wrapString(self.os_build),
                            wrapString(self.sdk_version),
                            wrapString(self.sdk_id),
                            wrapString(@""), // device id
                            wrapString(self.tag),
                            wrapString(self.manufacturer),
                            wrapString(self.domain),
                            wrapString(self.path),
                            wrapString(self.method),
                            wrapString(self.host_ip),
                            @(self.status_code),
                            @(self.start_timestamp),
                            @(self.response_time_stamp),
                            @(self.end_timestamp),
                            @(self.dns_time),
                            @(self.data_length),
                            @(self.network_error_code),
                            wrapString(self.network_error_msg)
                            ];
    __block NSString *result;
    [modelArray enumerateObjectsUsingBlock:^(NSString *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (0 == idx) {
            result = [NSString stringWithFormat:@"%@", obj];
        } else {
            result = [NSString stringWithFormat:@"%@\t%@", result, obj];
        }
    }];
    return result;
}

@end
