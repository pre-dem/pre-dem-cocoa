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


#import "PREDHelper.h"
#import "PreDemObjc.h"
#import "PREDPrivate.h"
#import "PREDVersion.h"
#import <QuartzCore/QuartzCore.h>
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

static NSString *const kPREDUtcDateFormatter = @"utcDateFormatter";
NSString *const kPREDExcludeApplicationSupportFromBackup = @"kPREDExcludeApplicationSupportFromBackup";

@implementation PREDHelper

+ (BOOL)isURLSessionSupported {
    id nsurlsessionClass = NSClassFromString(@"NSURLSessionUploadTask");
    BOOL isUrlSessionSupported = (nsurlsessionClass && !self.isRunningInAppExtension);
    return isUrlSessionSupported;
}

+ (NSString *)settingsDir {
    static NSString *settingsDir = nil;
    static dispatch_once_t predSettingsDir;
    
    dispatch_once(&predSettingsDir, ^{
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        
        // temporary directory for crashes grabbed from PLCrashReporter
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        settingsDir = [[paths objectAtIndex:0] stringByAppendingPathComponent:PRED_IDENTIFIER];
        
        if (![fileManager fileExistsAtPath:settingsDir]) {
            NSDictionary *attributes = [NSDictionary dictionaryWithObject: [NSNumber numberWithUnsignedLong: 0755] forKey: NSFilePosixPermissions];
            NSError *theError = NULL;
            
            [fileManager createDirectoryAtPath:settingsDir withIntermediateDirectories: YES attributes: attributes error: &theError];
        }
    });
    
    return settingsDir;
}

+ (NSString *)keychainPreDemObjcServiceName {
    static NSString *serviceName = nil;
    static dispatch_once_t predServiceName;
    
    dispatch_once(&predServiceName, ^{
        serviceName = [NSString stringWithFormat:@"%@.PreDemObjc", self.mainBundleIdentifier];
    });
    
    return serviceName;
}

+ (NSString *)mainBundleIdentifier {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

+ (NSString *)UUIDPreiOS6 {
    // Create a new UUID
    CFUUIDRef uuidObj = CFUUIDCreate(nil);
    
    // Get the string representation of the UUID
    NSString *resultUUID = (NSString*)CFBridgingRelease(CFUUIDCreateString(nil, uuidObj));
    CFRelease(uuidObj);
    
    return resultUUID;
}

+ (NSString *)UUID {
    NSString *resultUUID = nil;
    
    if ([NSUUID class]) {
        resultUUID = [[NSUUID UUID] UUIDString];
    } else {
        resultUUID = self.UUIDPreiOS6;
    }
    
    return resultUUID;
}

+ (BOOL)isPreiOS7Environment {
    static BOOL isPreiOS7Environment = YES;
    static dispatch_once_t checkOS;
    
    dispatch_once(&checkOS, ^{
        // NSFoundationVersionNumber_iOS_6_1 = 993.00
        // We hardcode this, so compiling with iOS 6 is possible while still being able to detect the correct environment
        
        // runtime check according to
        // https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/TransitionGuide/SupportingEarlieriOS.html
        if (floor(NSFoundationVersionNumber) <= 993.00) {
            isPreiOS7Environment = YES;
        } else {
            isPreiOS7Environment = NO;
        }
    });
    
    return isPreiOS7Environment;
}

+ (BOOL)isPreiOS8Environment {
    static BOOL isPreiOS8Environment = YES;
    static dispatch_once_t checkOS8;
    
    dispatch_once(&checkOS8, ^{
        // NSFoundationVersionNumber_iOS_7_1 = 1047.25
        // We hardcode this, so compiling with iOS 7 is possible while still being able to detect the correct environment
        
        // runtime check according to
        // https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/TransitionGuide/SupportingEarlieriOS.html
        if (floor(NSFoundationVersionNumber) <= 1047.25) {
            isPreiOS8Environment = YES;
        } else {
            isPreiOS8Environment = NO;
        }
    });
    
    return isPreiOS8Environment;
}

+ (BOOL)isPreiOS10Environment {
    static BOOL isPreOS10Environment = YES;
    static dispatch_once_t checkOS10;
    
    dispatch_once(&checkOS10, ^{
        // NSFoundationVersionNumber_iOS_9_MAX = 1299
        // We hardcode this, so compiling with iOS 7 is possible while still being able to detect the correct environment
        
        // runtime check according to
        // https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/TransitionGuide/SupportingEarlieriOS.html
        if (floor(NSFoundationVersionNumber) <= 1299.00) {
            isPreOS10Environment = YES;
        } else {
            isPreOS10Environment = NO;
        }
    });
    
    return isPreOS10Environment;
}


+ (BOOL)isAppStoreReceiptSandbox {
#if TARGET_OS_SIMULATOR
    return NO;
#else
    if (![NSBundle.mainBundle respondsToSelector:@selector(appStoreReceiptURL)]) {
        return NO;
    }
    NSURL *appStoreReceiptURL = NSBundle.mainBundle.appStoreReceiptURL;
    NSString *appStoreReceiptLastComponent = appStoreReceiptURL.lastPathComponent;
    
    BOOL isSandboxReceipt = [appStoreReceiptLastComponent isEqualToString:@"sandboxReceipt"];
    return isSandboxReceipt;
#endif
}

+ (BOOL)hasEmbeddedMobileProvision {
    BOOL hasEmbeddedMobileProvision = !![[NSBundle mainBundle] pathForResource:@"embedded" ofType:@"mobileprovision"];
    return hasEmbeddedMobileProvision;
}

+ (PREDEnvironment)currentAppEnvironment {
#if TARGET_OS_SIMULATOR
    return PREDEnvironmentOther;
#else
    
    // MobilePovision profiles are a clear indicator for Ad-Hoc distribution
    if (hasEmbeddedMobileProvision()) {
        return PREDEnvironmentOther;
    }
    
    // TestFlight is only supported from iOS 8 onwards, so at this point we have to be in the AppStore
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1) {
        return PREDEnvironmentAppStore;
    }
    
    if (isAppStoreReceiptSandbox()) {
        return PREDEnvironmentTestFlight;
    }
    
    return PREDEnvironmentAppStore;
#endif
}

+ (BOOL)isRunningInAppExtension {
    static BOOL isRunningInAppExtension = NO;
    static dispatch_once_t checkAppExtension;
    
    dispatch_once(&checkAppExtension, ^{
        isRunningInAppExtension = ([[[NSBundle mainBundle] executablePath] rangeOfString:@".appex/"].location != NSNotFound);
    });
    
    return isRunningInAppExtension;
}

+ (BOOL)isDebuggerAttached {
    static BOOL debuggerIsAttached = NO;
    
    static dispatch_once_t debuggerPredicate;
    dispatch_once(&debuggerPredicate, ^{
        struct kinfo_proc info;
        size_t info_size = sizeof(info);
        int name[4];
        
        name[0] = CTL_KERN;
        name[1] = KERN_PROC;
        name[2] = KERN_PROC_PID;
        name[3] = getpid();
        
        if (sysctl(name, 4, &info, &info_size, NULL, 0) == -1) {
            PREDLogError(@"Checking for a running debugger via sysctl() failed.");
            debuggerIsAttached = false;
        }
        
        if (!debuggerIsAttached && (info.kp_proc.p_flag & P_TRACED) != 0)
        debuggerIsAttached = true;
    });
    
    return debuggerIsAttached;
}

+ (NSString *)deviceType {
    
    UIUserInterfaceIdiom idiom = [UIDevice currentDevice].userInterfaceIdiom;
    
    switch (idiom) {
        case UIUserInterfaceIdiomPad:
            return @"Tablet";
        case UIUserInterfaceIdiomPhone:
            return @"Phone";
        default:
            return @"Unknown";
    }
}

+ (NSString *)osVersionBuild {
    void *result = NULL;
    size_t result_len = 0;
    int ret;
    
    /* If our buffer is too small after allocation, loop until it succeeds -- the requested destination size
     * may change after each iteration. */
    do {
        /* Fetch the expected length */
        if ((ret = sysctlbyname("kern.osversion", NULL, &result_len, NULL, 0)) == -1) {
            break;
        }
        
        /* Allocate the destination buffer */
        if (result != NULL) {
            free(result);
        }
        result = malloc(result_len);
        
        /* Fetch the value */
        ret = sysctlbyname("kern.osversion", result, &result_len, NULL, 0);
    } while (ret == -1 && errno == ENOMEM);
    
    /* Handle failure */
    if (ret == -1) {
        int saved_errno = errno;
        
        if (result != NULL) {
            free(result);
        }
        
        errno = saved_errno;
        return NULL;
    }
    
    NSString *osBuild = [NSString stringWithCString:result encoding:NSUTF8StringEncoding];
    free(result);
    
    NSString *osVersion = [[UIDevice currentDevice] systemVersion];
    
    return [NSString stringWithFormat:@"%@ (%@)", osVersion, osBuild];
}

+ (NSString *)osPlatform {
    return [[UIDevice currentDevice] systemName];
}

+ (NSString *)deviceLocale {
    NSLocale *locale = [NSLocale currentLocale];
    return [locale objectForKey:NSLocaleIdentifier];
}

+ (NSString *)deviceLanguage {
    return [[NSBundle mainBundle] preferredLocalizations][0];
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat:@"%@", [PREDVersion getSDKVersion]];
}

+ (NSString *)sdkBuild {
    return [NSString stringWithFormat:@"%@", [PREDVersion getSDKBuild]];
}

+ (NSString *)appVersion {
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    return version;
}

+ (NSString *)appBuild {
    NSString *build = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    return build;
}

+ (NSString *)appName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"];
}

+ (NSString *)appBundleId {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIdentifier"];
}

+ (NSString *)osVersion {
    return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)deviceModel {
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

+ (NSString *)executableUUID {
    const struct mach_header *executableHeader = NULL;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const struct mach_header *header = _dyld_get_image_header(i);
        if (header->filetype == MH_EXECUTE) {
            executableHeader = header;
            break;
        }
    }
    
    if (!executableHeader)
    return @"";
    
    BOOL is64bit = executableHeader->magic == MH_MAGIC_64 || executableHeader->magic == MH_CIGAM_64;
    uintptr_t cursor = (uintptr_t)executableHeader + (is64bit ? sizeof(struct mach_header_64) : sizeof(struct mach_header));
    const struct segment_command *segmentCommand = NULL;
    for (uint32_t i = 0; i < executableHeader->ncmds; i++, cursor += segmentCommand->cmdsize) {
        segmentCommand = (struct segment_command *)cursor;
        if (segmentCommand->cmd == LC_UUID) {
            const struct uuid_command *uuidCommand = (const struct uuid_command *)segmentCommand;
            const uint8_t *uuid = uuidCommand->uuid;
            return [[NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
                     uuid[0], uuid[1], uuid[2], uuid[3],
                     uuid[4], uuid[5], uuid[6], uuid[7],
                     uuid[8], uuid[9], uuid[10], uuid[11],
                     uuid[12], uuid[13], uuid[14], uuid[15]]
                    lowercaseString];
        }
    }
    
    return @"";
}

+ (NSBundle *)bundle {
    static NSBundle *bundle = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        NSString* mainBundlePath = [[NSBundle bundleForClass:[PREDManager class]] resourcePath];
        NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:PRED_BUNDLE];
        bundle = [NSBundle bundleWithPath:frameworkBundlePath];
    });
    return bundle;
}

+ (NSString *)localizedString:(NSString *)stringToken {
    if (!stringToken) return @"";
    
    NSString *appSpecificLocalizationString = NSLocalizedString(stringToken, @"");
    if (appSpecificLocalizationString && ![stringToken isEqualToString:appSpecificLocalizationString]) {
        return appSpecificLocalizationString;
    } else if (self.bundle) {
        NSString *bundleSpecificLocalizationString = NSLocalizedStringFromTableInBundle(stringToken, @"PreDemObjc", self.bundle, @"");
        if (bundleSpecificLocalizationString)
            return bundleSpecificLocalizationString;
        return stringToken;
    } else {
        return stringToken;
    }
}

+ (void)fixBackupAttributeForURL:(NSURL *)directoryURL {
    BOOL shouldExcludeAppSupportDirFromBackup = [[NSUserDefaults standardUserDefaults] boolForKey:kPREDExcludeApplicationSupportFromBackup];
    if (shouldExcludeAppSupportDirFromBackup) {
        return;
    }
    
    if (directoryURL) {
        NSError *getResourceError = nil;
        NSNumber *appSupportDirExcludedValue;
        
        if ([directoryURL getResourceValue:&appSupportDirExcludedValue forKey:NSURLIsExcludedFromBackupKey error:&getResourceError] && appSupportDirExcludedValue) {
            NSError *setResourceError = nil;
            [directoryURL setResourceValue:@NO forKey:NSURLIsExcludedFromBackupKey error:&setResourceError];
        }
    }
}

+ (NSString *)encodeAppIdentifier:(NSString *)inputString {
    return (inputString ? [self URLEncodedString:inputString] : [self URLEncodedString:self.mainBundleIdentifier]);
}

+ (NSString *)appName:(NSString *)placeHolderString {
    NSString *appName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
    if (!appName)
    appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];
    if (!appName)
    appName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleName"];
    if (!appName)
    appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?: placeHolderString;
    
    return appName;
}

+ (NSString *)URLEncodedString:(NSString *)inputString {
    
    // Requires iOS 7
    if ([inputString respondsToSelector:@selector(stringByAddingPercentEncodingWithAllowedCharacters:)]) {
        return [inputString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet characterSetWithCharactersInString:@"!*'();:@&=+$,/?%#[] {}"].invertedSet];
        
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
                                                                         (__bridge CFStringRef)inputString,
                                                                         NULL,
                                                                         CFSTR("!*'();:@&=+$,/?%#[] {}"),
                                                                         kCFStringEncodingUTF8)
                                 );
#pragma clang diagnostic pop
    }
}

NSString *base64String(NSData * data, unsigned long length) {
    SEL base64EncodingSelector = NSSelectorFromString(@"base64EncodedStringWithOptions:");
    if ([data respondsToSelector:base64EncodingSelector]) {
        return [data base64EncodedStringWithOptions:0];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        return [data base64Encoding];
#pragma clang diagnostic pop
    }
}

#pragma mark Context helpers

// Return ISO 8601 string representation of the date
+ (NSString *)utcDateString:(NSDate *)date{
    static NSDateFormatter *dateFormatter;
    
    // NSDateFormatter is not thread-safe prior to iOS 7
    if (self.isPreiOS7Environment) {
        NSMutableDictionary *threadDictionary = [NSThread currentThread].threadDictionary;
        dateFormatter = threadDictionary[kPREDUtcDateFormatter];
        
        if (!dateFormatter) {
            dateFormatter = [NSDateFormatter new];
            NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
            dateFormatter.locale = enUSPOSIXLocale;
            dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
            dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
            threadDictionary[kPREDUtcDateFormatter] = dateFormatter;
        }
        
        NSString *dateString = [dateFormatter stringFromDate:date];
        
        return dateString;
    }
    
    static dispatch_once_t dateFormatterToken;
    dispatch_once(&dateFormatterToken, ^{
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        dateFormatter = [NSDateFormatter new];
        dateFormatter.locale = enUSPOSIXLocale;
        dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        dateFormatter.timeZone = [NSTimeZone timeZoneForSecondsFromGMT:0];
    });
    
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    return dateString;
}

+ (NSDictionary*)getObjectData:(id)obj {
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int propsCount;
    
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    
    for(int i = 0;i < propsCount; i++) {
        
        objc_property_t prop = props[i];
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        id value = [obj valueForKey:propName];
        if(value == nil) {
            
            value = [NSNull null];
        } else {
            value = [self getObjectInternal:value];
        }
        [dic setObject:value forKey:propName];
    }
    
    return dic;
}

+ (id)getObjectInternal:(id)obj {
    
    if([obj isKindOfClass:[NSString class]]
       ||
       [obj isKindOfClass:[NSNumber class]]
       ||
       [obj isKindOfClass:[NSNull class]]) {
        
        return obj;
        
    }
    if([obj isKindOfClass:[NSArray class]]) {
        
        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        
        for(int i = 0; i < objarr.count; i++) {
            
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    if([obj isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        
        for(NSString *key in objdic.allKeys) {
            
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self getObjectData:obj];
    
}

+ (NSString *)MD5:(NSString *)mdStr {
    const char *original_str = [mdStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
    [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
}

@end

