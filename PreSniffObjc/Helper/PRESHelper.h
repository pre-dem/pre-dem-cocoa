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
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PreSniffSDKEnums.h"

@interface PRESHelper : NSObject

FOUNDATION_EXPORT NSString *const kBITExcludeApplicationSupportFromBackup;

+ (BOOL)isURLSessionSupported;

/*
 * Checks if the privacy description for iOS 10+ has been set in info plist.
 * @return YES for < iOS 10. YES/NO in iOS 10+ if NSPhotoLibraryUsageDescription is present in the app's Info.plist.
 */
+ (BOOL)isPhotoAccessPossible;

@end

NSString *pres_settingsDir(void);

BOOL pres_validateEmail(NSString *email);
NSString *pres_keychainHockeySDKServiceName(void);

/* Fix bug where Application Support was excluded from backup. */
void pres_fixBackupAttributeForURL(NSURL *directoryURL);

NSComparisonResult pres_versionCompare(NSString *stringA, NSString *stringB);
NSString *pres_mainBundleIdentifier(void);
NSString *pres_encodeAppIdentifier(NSString *inputString);
NSString *pres_appIdentifierToGuid(NSString *appIdentifier);
NSString *pres_appName(NSString *placeHolderString);
NSString *pres_UUIDPreiOS6(void);
NSString *pres_UUID(void);
NSString *pres_appAnonID(BOOL forceNewAnonID);
BOOL pres_isPreiOS7Environment(void);
BOOL pres_isPreiOS8Environment(void);
BOOL pres_isPreiOS10Environment(void);
BOOL pres_isAppStoreReceiptSandbox(void);
BOOL pres_hasEmbeddedMobileProvision(void);
PRESEnvironment pres_currentAppEnvironment(void);
BOOL pres_isRunningInAppExtension(void);

/**
 * Check if the debugger is attached
 *
 * Taken from https://github.com/plausiblelabs/plcrashreporter/blob/2dd862ce049e6f43feb355308dfc710f3af54c4d/Source/Crash%20Demo/main.m#L96
 *
 * @return `YES` if the debugger is attached to the current process, `NO` otherwise
 */
BOOL pres_isDebuggerAttached(void);

/* NSString helpers */
NSString *pres_URLEncodedString(NSString *inputString);
NSString *pres_base64String(NSData * data, unsigned long length);

/* Context helpers */
NSString *pres_utcDateString(NSDate *date);
NSString *pres_devicePlatform(void);
NSString *pres_devicePlatform(void);
NSString *pres_deviceType(void);
NSString *pres_osVersionBuild(void);
NSString *pres_osName(void);
NSString *pres_deviceLocale(void);
NSString *pres_deviceLanguage(void);
NSString *pres_screenSize(void);
NSString *pres_sdkVersion(void);
NSString *pres_appVersion(void);

#if !defined (HOCKEYSDK_CONFIGURATION_ReleaseCrashOnly) && !defined (HOCKEYSDK_CONFIGURATION_ReleaseCrashOnlyExtensions)
/* AppIcon helper */
NSString *pres_validAppIconStringFromIcons(NSBundle *resourceBundle, NSArray *icons);
NSString *pres_validAppIconFilename(NSBundle *bundle, NSBundle *resourceBundle);

/* UIImage helpers */
UIImage *pres_roundedCornerImage(UIImage *inputImage, NSInteger cornerSize, NSInteger borderSize);
UIImage *pres_imageToFitSize(UIImage *inputImage, CGSize fitSize, BOOL honorScaleFactor);
UIImage *pres_reflectedImageWithHeight(UIImage *inputImage, NSUInteger height, float fromAlpha, float toAlpha);

UIImage *pres_newWithContentsOfResolutionIndependentFile(NSString * path);
UIImage *pres_imageWithContentsOfResolutionIndependentFile(NSString * path);
UIImage *pres_imageNamed(NSString *imageName, NSString *bundleName);
UIImage *pres_screenshot(void);
UIImage *pres_appIcon(void);

#endif
