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

+ (NSMutableDictionary *)parseQuery:(NSString *)query;

/***************************************************************************//**
 Uses zlib to compress the given data. Note that gzip headers will be added so
 that the data can be easily decompressed using a tool like WinZip, gunzip, etc.

 Note: Special thanks to Robbie Hanson of Deusty Designs for sharing sample code
 showing how deflateInit2() can be used to make zlib generate a compressed file
 with gzip headers:

http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html

 @param pUncompressedData memory buffer of bytes to compress
 @return Compressed data as an NSData object
 */
+ (NSData *)gzipData:(NSData *)pUncompressedData error:(NSError **)error;

@end
