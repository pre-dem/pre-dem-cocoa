//
//  PRESCrashReportTextFormatterPrivate.h
//  PreSniffObjc
//
//  Created by Lukas Spieß on 27/01/16.
//
//

#import "PRESCrashReportTextFormatter.h"

#ifndef PRESCrashReportTextFormatterPrivate_h
#define PRESCrashReportTextFormatterPrivate_h

@interface PRESCrashReportTextFormatter ()

+ (NSString *)anonymizedPathFromPath:(NSString *)path;

@end

#endif /* PRESCrashReportTextFormatterPrivate_h */
