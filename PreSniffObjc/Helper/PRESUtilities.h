//
//  PRESUtilities.h
//  PreSniffSDK
//
//  Created by WangSiyu on 06/04/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PRESUtilities : NSObject

+ (NSString *)getAppName;
+ (NSString *)getAppBundleId;
+ (NSString *)getOsVersion;
+ (NSString *)getDeviceModel;
+ (NSString *)getDeviceUUID;
+ (NSDictionary*)getObjectData:(id)obj;

@end
