//
//  PREDHelper.m
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//


#import "PREDHelper.h"
#import "PREDVersion.h"
#import <sys/sysctl.h>
#import <objc/runtime.h>
#import <CommonCrypto/CommonDigest.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "netdb.h"
#import "arpa/inet.h"

static NSString *const kPREDDirectoryName = @"com.qiniu.predem";
static NSString *const kPREDKeychainServiceName = @"com.qiniu.predem";
static NSString *const kPREDUUIDKeychainName = @"uuid";

__strong static NSString *_tag = @"";

@implementation PREDHelper

+ (NSString *)UUID {
    NSString *resultUUID = [self readUUIDFromKeyChain];
    if (!resultUUID) {
        resultUUID = [self generateNewUUIDString];
    }
    return resultUUID;
}

+ (NSString *)readUUIDFromKeyChain {
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kPREDKeychainServiceName];
    NSString *UUID = [keychain stringForKey:kPREDUUIDKeychainName];
    return UUID;
}

+ (NSString *)generateNewUUIDString {
    CFUUIDRef uuidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef strRef = CFUUIDCreateString(kCFAllocatorDefault, uuidRef);
    NSString *uuidString = [NSString stringWithString:(__bridge NSString *) strRef];
    CFRelease(strRef);
    CFRelease(uuidRef);
    UICKeyChainStore *keychain = [UICKeyChainStore keyChainStoreWithService:kPREDKeychainServiceName];
    [keychain setString:uuidString forKey:kPREDUUIDKeychainName];
    return uuidString;
}

+ (NSString *)osPlatform {
    return [[UIDevice currentDevice] systemName];
}

+ (NSString *)sdkVersion {
    return [NSString stringWithFormat:@"%@", [PREDVersion getSDKVersion]];
}

+ (NSString *)appVersion {
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
    return version;
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

+ (NSString *)osBuild {
    size_t size;
    sysctlbyname("kern.osversion", NULL, &size, NULL, 0);
    char *answer = (char *) malloc(size);
    if (answer == NULL)
        return nil;
    sysctlbyname("kern.osversion", answer, &size, NULL, 0);
    NSString *osBuild = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    free(answer);
    return osBuild;
}

+ (NSString *)deviceModel {
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *answer = (char *) malloc(size);
    if (answer == NULL)
        return @"";
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    NSString *platform = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
    free(answer);
    return platform;
}

+ (void)setTag:(NSString *)tag {
    if (!tag) {
        _tag = @"";
    } else {
        _tag = tag.copy;
    }
}

+ (NSString *)tag {
    return _tag;
}

+ (NSString *)sdkDirectory {
    return [NSString stringWithFormat:@"%@%@", [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask][0] absoluteString] substringFromIndex:7], kPREDDirectoryName];
}

+ (NSString *)cacheDirectory {
    return [NSString stringWithFormat:@"%@/%@", self.sdkDirectory, @"cache"];
}

#pragma mark Context helpers

+ (NSString *)MD5:(NSString *)mdStr {
    const char *original_str = [mdStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, (unsigned int) strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
}

+ (NSString *)lookupHostIPAddressForURL:(NSURL *)url {
    if (!url) {
        return nil;
    }
    const char *host = [[url host] UTF8String];
    if (host == NULL) {
        return nil;
    }
    // Ask the unix subsytem to query the DNS
    struct hostent *remoteHostEnt = gethostbyname(host);
    if (remoteHostEnt == NULL || remoteHostEnt->h_addr_list == NULL) {
        return nil;
    }
    // Get address info from host entry
    struct in_addr *remoteInAddr = (struct in_addr *) remoteHostEnt->h_addr_list[0];
    if (remoteInAddr == NULL) {
        return nil;
    }
    // Convert numeric addr to ASCII string
    char *sRemoteInAddr = inet_ntoa(*remoteInAddr);
    if (sRemoteInAddr == NULL) {
        return nil;
    }
    // hostIP
    NSString *hostIP = [NSString stringWithUTF8String:sRemoteInAddr];
    return hostIP;
}

+ (NSMutableDictionary *)parseQuery:(NSString *)query {
    NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
    NSArray *urlComponents = [query componentsSeparatedByString:@"&"];
    for (NSString *keyValuePair in urlComponents) {
        NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
        NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
        NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
        queryStringDictionary[key] = value;
    }
    return queryStringDictionary;
}

@end

