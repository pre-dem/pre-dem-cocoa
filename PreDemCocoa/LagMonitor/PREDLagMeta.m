//
//  PREDLagMeta.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDLagMeta.h"
#import "PREDHelper.h"
#import "PREDCrashReportTextFormatter.h"
#import "PREDConstants.h"

#define PREDMillisecondPerSecond            1000

@implementation PREDLagMeta

- (instancetype)initWithReport:(PREDPLCrashReport *)report {
    if (self = [self initWithName:LagMonitorEventName type:AutoCapturedEventType]) {
        if (report.uuidRef != NULL) {
            _report_uuid = (NSString *) CFBridgingRelease(CFUUIDCreateString(NULL, report.uuidRef));
        }
        _lag_log_key = [PREDCrashReportTextFormatter stringValueForCrashReport:report crashReporterKey:PREDHelper.UUID];
        _lag_time = [report.systemInfo.timestamp timeIntervalSince1970] * PREDMillisecondPerSecond;
        if ([report.processInfo respondsToSelector:@selector(processStartTime)]) {
            if (report.systemInfo.timestamp && report.processInfo.processStartTime) {
                _start_time = [report.processInfo.processStartTime timeIntervalSince1970] * PREDMillisecondPerSecond;
            }
        }
    }
    return self;
}

@end
