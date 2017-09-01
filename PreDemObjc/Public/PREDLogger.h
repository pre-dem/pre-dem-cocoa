//
//  PREDLogger.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"

static const DDLogLevel predLogLevel = DDLogLevelAll;

#define PREDLogError(frmt, ...)   LOG_MAYBE(NO,                predLogLevel, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

#define PREDTagLogError(tag, frmt, ...)   LOG_MAYBE(NO,                predLogLevel, DDLogFlagError,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDTagLogWarn(tag, frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagWarning, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDTagLogInfo(tag, frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagInfo,    0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDTagLogDebug(tag, frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagDebug,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)
#define PREDTagLogVerbose(tag, frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagVerbose, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)


@interface PREDLogger : NSObject

@property(class, nonatomic, assign) PREDLogLevel logLevel;

+ (void)startCaptureLogWithLevel:(PREDLogLevel)logLevel;
+ (void)stopCaptureLog;

@end
