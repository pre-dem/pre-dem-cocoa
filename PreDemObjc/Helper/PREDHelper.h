/*
 * Author: Andreas Linde <mail@andreaslinde.de>
 *
 * Copyright (c) 2012-2014 HockeyApp, Bit Stadium GmbH.
 * All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 *
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPREDS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PREDEnums.h"

@interface PREDHelper : NSObject

FOUNDATION_EXPORT NSString *const kPREDExcludeApplicationSupportFromBackup;

@property(class, readonly) BOOL isURLSessionSupported;
@property(class, readonly) NSString *settingsDir;
@property(class, readonly) NSString *keychainPreDemObjcServiceName;
@property(class, readonly) NSString *mainBundleIdentifier;
@property(class, readonly) NSString *UUIDPreiOS6;
@property(class, readonly) NSString *UUID;
@property(class, readonly) BOOL isPreiOS7Environment;
@property(class, readonly) BOOL isPreiOS8Environment;
@property(class, readonly) BOOL isPreiOS10Environment;
@property(class, readonly) BOOL isAppStoreReceiptSandbox;
@property(class, readonly) BOOL hasEmbeddedMobileProvision;
@property(class, readonly) PREDEnvironment currentAppEnvironment;
@property(class, readonly) BOOL isRunningInAppExtension;
@property(class, readonly) BOOL isDebuggerAttached;
@property(class, readonly) NSString *deviceType;
@property(class, readonly) NSString *osVersionBuild;
@property(class, readonly) NSString *osName;
@property(class, readonly) NSString *deviceLocale;
@property(class, readonly) NSString *deviceLanguage;
@property(class, readonly) NSString *screenSize;
@property(class, readonly) NSString *sdkVersion;
@property(class, readonly) NSString *appVersion;
@property(class, readonly) NSString *appAnonID;
@property(class, readonly) NSString *appName;
@property(class, readonly) NSString *appBundleId;
@property(class, readonly) NSString *osVersion;
@property(class, readonly) NSString *deviceModel;
@property(class, readonly) NSString *executableUUID;

+ (void)fixBackupAttributeForURL:(NSURL *)directoryURL;
+ (NSString *)encodeAppIdentifier:(NSString *)inputString;
+ (NSString *)appName:(NSString *)placeHolderString;
+ (NSString *)URLEncodedString:(NSString *)inputString;
+ (NSString *)utcDateString:(NSDate *)date;
+ (NSDictionary*)getObjectData:(id)obj;
+ (NSString *)MD5:(NSString *)mdStr;

@end
