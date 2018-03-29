//
//  PREDHelper.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"

@interface PREDHelper : NSObject

@property(class, readonly) NSString *UUID;
@property(class, readonly) NSString *osPlatform;
@property(class, readonly) NSString *sdkVersion;
@property(class, readonly) NSString *appVersion;
@property(class, readonly) NSString *appName;
@property(class, readonly) NSString *appBundleId;
@property(class, readonly) NSString *osVersion;
@property(class, readonly) NSString *osBuild;
@property(class, readonly) NSString *deviceModel;


@property(class, strong) NSString *tag;
@property(class, readonly) NSString *sdkDirectory;
@property(class, readonly) NSString *cacheDirectory;

+ (NSString *)MD5:(NSString *)mdStr;

+ (NSString *)lookupHostIPAddressForURL:(NSURL *)url;

@end
