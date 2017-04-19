//
//  PRESUtilities.m
//  PreSniffSDK
//
//  Created by WangSiyu on 06/04/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PRESUtilities.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>

@implementation PRESUtilities

+ (NSString *)getAppName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
}

+ (NSString *)getAppBundleId {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

+ (NSString *)getOsVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)getDeviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *answer = (char*)malloc(size);
    if (answer == NULL)
        return @"";
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:answer encoding: NSUTF8StringEncoding];
    free(answer);
    return platform;
}

+ (NSString *)getDeviceUUID {
    NSString * uuid = [[UIDevice currentDevice] identifierForVendor].UUIDString;
    if(uuid == nil){
        return @"simulator";
    }
    return uuid;
}

@end
