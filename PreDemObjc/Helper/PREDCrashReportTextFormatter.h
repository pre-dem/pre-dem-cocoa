//
//  PREDCrashReportTextFormatter.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PLCrashReport;


// Dictionary keys for array elements returned by arrayOfAppUUIDsForCrashReport:
#ifndef kPREDBinaryImageKeyUUID
#define kPREDBinaryImageKeyUUID @"uuid"
#define kPREDBinaryImageKeyArch @"arch"
#define kPREDBinaryImageKeyType @"type"
#endif


/**
 *  PreDemObjc Crash Reporter error domain
 */
typedef NS_ENUM (NSInteger, PREDBinaryImageType) {
    /**
     *  App binary
     */
    PREDBinaryImageTypeAppBinary,
    /**
     *  App provided framework
     */
    PREDBinaryImageTypeAppFramework,
    /**
     *  Image not related to the app
     */
    PREDBinaryImageTypeOther
};


@interface PREDCrashReportTextFormatter : NSObject

+ (NSString *)stringValueForCrashReport:(PLCrashReport *)report crashReporterKey:(NSString *)crashReporterKey;
+ (NSArray *)arrayOfAppUUIDsForCrashReport:(PLCrashReport *)report;
+ (NSString *)pres_archNameFromCPUType:(uint64_t)cpuType subType:(uint64_t)subType;
+ (PREDBinaryImageType)pres_imageTypeForImagePath:(NSString *)imagePath processPath:(NSString *)processPath;

@end
