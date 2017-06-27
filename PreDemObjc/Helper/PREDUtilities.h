//
//  PREDUtilities.h
//  PreDemSDK
//
//  Created by WangSiyu on 06/04/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PREDUtilities : NSObject

+ (NSString *)getAppName;
+ (NSString *)getAppBundleId;
+ (NSString *)getOsVersion;
+ (NSString *)getDeviceModel;
+ (NSString *)getDeviceUUID;
+ (NSDictionary*)getObjectData:(id)obj;
+ (NSString *)MD5:(NSString *)mdStr;

@end
