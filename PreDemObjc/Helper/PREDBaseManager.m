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

#import "PreDemObjc.h"
#import "PREDPrivate.h"

#import "PREDHelper.h"

#import "PREDBaseManager.h"
#import "PREDBaseManagerPrivate.h"

#import "PREDKeychainUtils.h"

#import <sys/sysctl.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

#ifndef __IPHONE_6_1
#define __IPHONE_6_1     60100
#endif

@implementation PREDBaseManager {
    UINavigationController *_navController;
    
    NSDateFormatter *_rfc3339Formatter;
}


- (instancetype)init {
    if ((self = [super init])) {
        _serverURL = PRED_URL;        
        NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        _rfc3339Formatter = [[NSDateFormatter alloc] init];
        [_rfc3339Formatter setLocale:enUSPOSIXLocale];
        [_rfc3339Formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
        [_rfc3339Formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    }
    return self;
}

- (instancetype)initWithAppIdentifier:(NSString *)appIdentifier appEnvironment:(PREDEnvironment)environment {
    if ((self = [self init])) {
        _appIdentifier = appIdentifier;
        _appEnvironment = environment;
    }
    return self;
}


#pragma mark - Private

- (void)reportError:(NSError *)error {
    PREDLogError(@"%@", [error localizedDescription]);
}

- (NSString *)encodedAppIdentifier {
    return [PREDHelper encodeAppIdentifier:_appIdentifier];
}

- (NSString *)getDevicePlatform {
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

- (NSString *)executableUUID {
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

- (BOOL)addStringValueToKeychain:(NSString *)stringValue forKey:(NSString *)key {
    if (!key || !stringValue)
        return NO;
    
    NSError *error = nil;
    return [PREDKeychainUtils storeUsername:key
                                andPassword:stringValue
                             forServiceName:PREDHelper.keychainPreDemObjcServiceName
                             updateExisting:YES
                                      error:&error];
}

- (BOOL)addStringValueToKeychainForThisDeviceOnly:(NSString *)stringValue forKey:(NSString *)key {
    if (!key || !stringValue)
        return NO;
    
    NSError *error = nil;
    return [PREDKeychainUtils storeUsername:key
                                andPassword:stringValue
                             forServiceName:PREDHelper.keychainPreDemObjcServiceName
                             updateExisting:YES
                              accessibility:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                                      error:&error];
}

- (NSString *)stringValueFromKeychainForKey:(NSString *)key {
    if (!key)
        return nil;
    
    NSError *error = nil;
    return [PREDKeychainUtils getPasswordForUsername:key
                                      andServiceName:PREDHelper.keychainPreDemObjcServiceName
                                               error:&error];
}

- (BOOL)removeKeyFromKeychain:(NSString *)key {
    NSError *error = nil;
    return [PREDKeychainUtils deleteItemForUsername:key
                                     andServiceName:PREDHelper.keychainPreDemObjcServiceName
                                              error:&error];
}


#pragma mark - Manager Control

- (void)startManager {
}

#pragma mark - Helpers

- (NSDate *)parseRFC3339Date:(NSString *)dateString {
    NSDate *date = nil;
    NSError *error = nil; 
    if (![_rfc3339Formatter getObjectValue:&date forString:dateString range:nil error:&error]) {
        PREDLogWarning(@"WARNING: Invalid date '%@' string: %@", dateString, error);
    }
    
    return date;
}


@end
