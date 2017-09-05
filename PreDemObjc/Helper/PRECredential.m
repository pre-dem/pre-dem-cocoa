//
//  PRECredential.m
//  Pods
//
//  Created by BaiLong on 2017/9/5.
//
//

#include <CommonCrypto/CommonCrypto.h>

#import "PRECredential.h"

@implementation PRECredential

+(NSString *)authoriztion:(NSString*) data
                    appKey:(NSString*) key{
    NSString* realK = [key substringFromIndex:8];
    return [NSString stringWithFormat:@"DEMv1 %@", [self HmacSha1:data data:realK]];
}

+(NSString *)HmacSha1:(NSString *)key data:(NSString *)data
{
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char sha1HMAC[CC_SHA1_DIGEST_LENGTH];
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), sha1HMAC);
    
    NSData *HMAC = [[NSData alloc] initWithBytes:sha1HMAC length:sizeof(sha1HMAC)];
    
    NSString *hash = [HMAC base64EncodedStringWithOptions:0];
    return hash;
}

@end
