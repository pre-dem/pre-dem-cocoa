//
//  PREDCrashMeta.m
//  Pods
//
//  Created by 王思宇 on 15/09/2017.
//
//

#import "PREDCrashMeta.h"
#import <CrashReporter/CrashReporter.h>
#import "PREDHelper.h"
#import "PREDCrashReportTextFormatter.h"

#define PREDMillisecondPerSecond            1000

@implementation PREDCrashMeta

- (instancetype)initWithData:(NSData *)data error:(NSError **)error {
    if (self = [super init]) {
        PREDPLCrashReport *report = [[PREDPLCrashReport alloc] initWithData:data error:error];
        if (*error) {
            return self;
        }
        if (report.uuidRef != NULL) {
            _report_uuid = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef));
        }
        _crash_log_key = [PREDCrashReportTextFormatter stringValueForCrashReport:report crashReporterKey:PREDHelper.UUID];
        _crash_time = [report.systemInfo.timestamp timeIntervalSince1970] * PREDMillisecondPerSecond;
        if ([report.processInfo respondsToSelector:@selector(processStartTime)]) {
            if (report.systemInfo.timestamp && report.processInfo.processStartTime) {
                _start_time = [report.processInfo.processStartTime timeIntervalSince1970] * PREDMillisecondPerSecond;
            }
        }
    }
    return self;
}

@end
