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
#import <CommonCrypto/CommonDigest.h>
#import <UICKeyChainStore/UICKeyChainStore.h>
#import "netdb.h"
#import "arpa/inet.h"
#import "zlib.h"
#import "PREDLogger.h"
#import "PREDError.h"

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

/*******************************************************************************
 See header for documentation.
 */
+ (NSData *)gzipData:(NSData *)pUncompressedData error:(NSError **)error {
    /*
     Special thanks to Robbie Hanson of Deusty Designs for sharing sample code
     showing how deflateInit2() can be used to make zlib generate a compressed
     file with gzip headers:

http://deusty.blogspot.com/2007/07/gzip-compressiondecompression.html

     */

    if (!pUncompressedData || [pUncompressedData length] == 0) {
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeCompressionError description:@"%s: Error: Can't compress an empty or null NSData object.", __func__];
        }
        return nil;
    }

    /* Before we can begin compressing (aka "deflating") data using the zlib
     functions, we must initialize zlib. Normally this is done by calling the
     deflateInit() function; in this case, however, we'll use deflateInit2() so
     that the compressed data will have gzip headers. This will make it easy to
     decompress the data later using a tool like gunzip, WinZip, etc.

     deflateInit2() accepts many parameters, the first of which is a C struct of
     type "z_stream" defined in zlib.h. The properties of this struct are used to
     control how the compression algorithms work. z_stream is also used to
     maintain pointers to the "input" and "output" byte buffers (next_in/out) as
     well as information about how many bytes have been processed, how many are
     left to process, etc. */
    z_stream zlibStreamStruct;
    zlibStreamStruct.zalloc = Z_NULL; // Set zalloc, zfree, and opaque to Z_NULL so
    zlibStreamStruct.zfree = Z_NULL; // that when we call deflateInit2 they will be
    zlibStreamStruct.opaque = Z_NULL; // updated to use default allocation functions.
    zlibStreamStruct.total_out = 0; // Total number of output bytes produced so far
    zlibStreamStruct.next_in = (Bytef *) [pUncompressedData bytes]; // Pointer to input bytes
    zlibStreamStruct.avail_in = [pUncompressedData length]; // Number of input bytes left to process

    /* Initialize the zlib deflation (i.e. compression) internals with deflateInit2().
     The parameters are as follows:

     z_streamp strm - Pointer to a zstream struct
     int level      - Compression level. Must be Z_DEFAULT_COMPRESSION, or between
                      0 and 9: 1 gives best speed, 9 gives best compression, 0 gives
                      no compression.
     int method     - Compression method. Only method supported is "Z_DEFLATED".
     int windowBits - Base two logarithm of the maximum window size (the size of
                      the history buffer). It should be in the range 8..15. Add
                      16 to windowBits to write a simple gzip header and trailer
                      around the compressed data instead of a zlib wrapper. The
                      gzip header will have no file name, no extra data, no comment,
                      no modification time (set to zero), no header crc, and the
                      operating system will be set to 255 (unknown).
     int memLevel   - Amount of memory allocated for internal compression state.
                      1 uses minimum memory but is slow and reduces compression
                      ratio; 9 uses maximum memory for optimal speed. Default value
                      is 8.
     int strategy   - Used to tune the compression algorithm. Use the value
                      Z_DEFAULT_STRATEGY for normal data, Z_FILTERED for data
                      produced by a filter (or predictor), or Z_HUFFMAN_ONLY to
                      force Huffman encoding only (no string match) */
    int initError = deflateInit2(&zlibStreamStruct, Z_DEFAULT_COMPRESSION, Z_DEFLATED, (15 + 16), 8, Z_DEFAULT_STRATEGY);
    if (initError != Z_OK) {
        NSString *errorMsg = nil;
        switch (initError) {
            case Z_STREAM_ERROR:
                errorMsg = @"Invalid parameter passed in to function.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Insufficient memory.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeCompressionError description:@"%s: deflateInit2() Error: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg];
        }
        return nil;
    }

    // Create output memory buffer for compressed data. The zlib documentation states that
    // destination buffer size must be at least 0.1% larger than avail_in plus 12 bytes.
    NSMutableData *compressedData = [NSMutableData dataWithLength:(NSUInteger) ([pUncompressedData length] * 1.01 + 12)];

    int deflateStatus;
    do {
        // Store location where next byte should be put in next_out
        zlibStreamStruct.next_out = [compressedData mutableBytes] + zlibStreamStruct.total_out;

        // Calculate the amount of remaining free space in the output buffer
        // by subtracting the number of bytes that have been written so far
        // from the buffer's total capacity
        zlibStreamStruct.avail_out = [compressedData length] - zlibStreamStruct.total_out;

        /* deflate() compresses as much data as possible, and stops/returns when
         the input buffer becomes empty or the output buffer becomes full. If
         deflate() returns Z_OK, it means that there are more bytes left to
         compress in the input buffer but the output buffer is full; the output
         buffer should be expanded and deflate should be called again (i.e., the
         loop should continue to rune). If deflate() returns Z_STREAM_END, the
         end of the input stream was reached (i.e.g, all of the data has been
         compressed) and the loop should stop. */
        deflateStatus = deflate(&zlibStreamStruct, Z_FINISH);

    } while (deflateStatus == Z_OK);

    // Check for zlib error and convert code to usable error message if appropriate
    if (deflateStatus != Z_STREAM_END) {
        NSString *errorMsg = nil;
        switch (deflateStatus) {
            case Z_ERRNO:
                errorMsg = @"Error occured while reading file.";
                break;
            case Z_STREAM_ERROR:
                errorMsg = @"The stream state was inconsistent (e.g., next_in or next_out was NULL).";
                break;
            case Z_DATA_ERROR:
                errorMsg = @"The deflate data was invalid or incomplete.";
                break;
            case Z_MEM_ERROR:
                errorMsg = @"Memory could not be allocated for processing.";
                break;
            case Z_BUF_ERROR:
                errorMsg = @"Ran out of output buffer for writing compressed bytes.";
                break;
            case Z_VERSION_ERROR:
                errorMsg = @"The version of zlib.h and the version of the library linked do not match.";
                break;
            default:
                errorMsg = @"Unknown error code.";
                break;
        }
        if (error) {
            *error = [PREDError GenerateNSError:kPREDErrorCodeCompressionError description:@"%s: zlib error while attempting compression: \"%@\" Message: \"%s\"", __func__, errorMsg, zlibStreamStruct.msg];
        }
        // Free data structures that were dynamically created for the stream.
        deflateEnd(&zlibStreamStruct);

        return nil;
    }
    // Free data structures that were dynamically created for the stream.
    deflateEnd(&zlibStreamStruct);
    [compressedData setLength:zlibStreamStruct.total_out];
    PREDLogDebug(@"%s: Compressed file from %d B to %d B", __func__, [pUncompressedData length], [compressedData length]);

    return compressedData;
}

@end

