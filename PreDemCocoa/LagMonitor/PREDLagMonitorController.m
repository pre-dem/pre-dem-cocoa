//
//  PREDLagMonitorController.m
//  Pods
//
//  Created by WangSiyu on 06/07/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLagMonitorController.h"
#import "PREDCrashReportTextFormatter.h"

@implementation PREDLagMonitorController {
    CFRunLoopObserverRef _observer;
    dispatch_semaphore_t _semaphore;
    CFRunLoopActivity _activity;
    NSInteger _countTime;
    PREDPLCrashReporter *_reporter;
    PREDPersistence *_persistence;
    NSDate *_lastSendTime;
    PREDPLCrashReport *_lastLagReport;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    PREDLagMonitorController *instrance = (__bridge PREDLagMonitorController *) info;
    instrance->_activity = activity;
    // 发送信号
    dispatch_semaphore_t semaphore = instrance->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

- (instancetype)initWithPersistence:(PREDPersistence *)persistence {
    if (self = [super init]) {
        PLCrashReporterSignalHandlerType signalHandlerType = PLCrashReporterSignalHandlerTypeBSD;
        PREDPLCrashReporterConfig *config = [[PREDPLCrashReporterConfig alloc] initWithSignalHandlerType:signalHandlerType
                                                                                   symbolicationStrategy:PLCrashReporterSymbolicationStrategyNone];
        _reporter = [[PREDPLCrashReporter alloc] initWithConfiguration:config];
        _persistence = persistence;
    }
    return self;
}

- (void)dealloc {
    self.started = NO;
}

- (void)setStarted:(BOOL)started {
    if (_started == started) {
        return;
    }
    _started = started;
    if (started) {
        PREDLogDebug(@"Starting lag monitor");
        [self registerObserver];
    } else {
        PREDLogDebug(@"Terminating lag monitor");
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
        CFRelease(_observer);
        _observer = NULL;
    }
}

- (void)registerObserver {
    CFRunLoopObserverContext context = {0, (__bridge void *) self, NULL, NULL};
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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (_started) {
            // 假定连续5次超时100ms认为卡顿(当然也包含了单次超时500ms)
            // 每分钟至多只采集一次
            long st = dispatch_semaphore_wait(_semaphore, dispatch_time(DISPATCH_TIME_NOW, 100 * NSEC_PER_MSEC));
            if (st != 0 &&
                    (_activity == kCFRunLoopBeforeSources || _activity == kCFRunLoopAfterWaiting) &&
                    (!_lastSendTime || [[NSDate date] timeIntervalSinceDate:_lastSendTime] >= 60)) {
                if (++_countTime < 5)
                    continue;
                [self sendLagStack];
                _lastSendTime = [NSDate date];
            }
            _countTime = 0;
        }
    });
}

- (void)sendLagStack {
    NSError *error;
    NSData *data = [_reporter generateLiveReportAndReturnError:&error];
    if (error) {
        PREDLogError(@"generate lag report error: %@", error);
        return;
    }
    PREDPLCrashReport *report = [[PREDPLCrashReport alloc] initWithData:data error:&error];
    if (error) {
        PREDLogError(@"parse lag report error: %@", error);
        return;
    }

    if ([PREDCrashReportTextFormatter isReport:_lastLagReport equivalentWith:report]) {
        PREDLogInfo(@"generated a equal report: %@", report);
        return;
    }

    _lastLagReport = report;

    PREDLagMeta *meta = [[PREDLagMeta alloc] initWithReport:report];

    [_persistence persistLagMeta:meta];
}

@end
