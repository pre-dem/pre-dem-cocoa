//
//  PREDLagMonitorController.m
//  Pods
//
//  Created by WangSiyu on 06/07/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLagMonitorController.h"
#import <CrashReporter/CrashReporter.h>
#import "PREDCrashReportTextFormatter.h"
#import "PREDHelper.h"

@implementation PREDLagMonitorController {
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
    NSInteger _countTime;
    PREPLCrashReporter *_reporter;
    PREPLCrashReport *_lastReport;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    PREDLagMonitorController *instrance = (__bridge PREDLagMonitorController *)info;
    instrance->_activity = activity;
    // 发送信号
    dispatch_semaphore_t semaphore = instrance->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (instancetype)init {
    if (self = [super init]) {
        _reporter = [[PREPLCrashReporter alloc] initWithConfiguration:[PREPLCrashReporterConfig defaultConfiguration]];
    }
    return self;
}

- (void) startMonitor {
    if (_observer) {
        return;
    }
    [self registerObserver];
}

- (void) endMonitor {
    if (!_observer) {
        return;
    }
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

- (void)registerObserver {
    CFRunLoopObserverContext context = {0,(__bridge void*)self,NULL,NULL};
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    
    // 创建信号
    _semaphore = dispatch_semaphore_create(0);
    
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        while (YES) {
            // 假定连续5次超时50ms认为卡顿(当然也包含了单次超时250ms)
            long st = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
            if (st != 0) {
                if (_activity==kCFRunLoopBeforeSources || _activity==kCFRunLoopAfterWaiting) {
                    if (++_countTime < 5)
                        continue;
                    [self sendLagStack];
                }
            }
            _countTime = 0;
        }
    });
}

- (void)sendLagStack {
    NSError *err;
    NSData *data = [_reporter generateLiveReportAndReturnError:&err];
    if (err) {
        return;
    }
    
    PREPLCrashReport *report = [[PREPLCrashReport alloc] initWithData:data error:&err];
    if (err) {
        return;
    }
    NSString *crashLog = [PREDCrashReportTextFormatter stringValueForCrashReport:report crashReporterKey:PREDHelper.appName];
    if ([PREDCrashReportTextFormatter isReport:report euivalentWith:_lastReport]) {
        return;
    }
    _lastReport = report;
    [[crashLog dataUsingEncoding:NSUTF8StringEncoding] writeToURL:[NSURL URLWithString:@"crash.log" relativeToURL:[NSFileManager defaultManager].temporaryDirectory] atomically:YES];
}

@end
