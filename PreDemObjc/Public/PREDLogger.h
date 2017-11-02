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

/**
 * 以 error 级别打印 log
 */
#define PREDLogError(frmt, ...)   LOG_MAYBE(NO,                predLogLevel, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 warn 级别打印 log
 */
#define PREDLogWarn(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 info 级别打印 log
 */
#define PREDLogInfo(frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 debug 级别打印 log
 */
#define PREDLogDebug(frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 verbose 级别打印 log
 */
#define PREDLogVerbose(frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 error 级别打印带有 tag 的 log
 */
#define PREDTagLogError(tag, frmt, ...)   LOG_MAYBE(NO,                predLogLevel, DDLogFlagError,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 warn 级别打印带有 tag 的 log
 */
#define PREDTagLogWarn(tag, frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagWarning, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 info 级别打印带有 tag 的 log
 */
#define PREDTagLogInfo(tag, frmt, ...)    LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagInfo,    0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 debug 级别打印带有 tag 的 log
 */
#define PREDTagLogDebug(tag, frmt, ...)   LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagDebug,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 verbose 级别打印带有 tag 的 log
 */
#define PREDTagLogVerbose(tag, frmt, ...) LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagVerbose, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * logger 核心类，提供日志打印相关接口
 */
@interface PREDLogger : NSObject

/**
 * 控制台 log 打印的级别
 */
@property(class, nonatomic, assign) PREDLogLevel ttyLogLevel;

/**
 * 开始采集 log 上报到服务器
 *
 * @param logLevel 采集的 log 级别，例如 PREDLogLevelWarning 将采集 error 及 warn 级别的 log 进行上报
 */
+ (void)startCaptureLogWithLevel:(PREDLogLevel)logLevel;

/**
 * 停止采集 log 上报到服务器
 */
+ (void)stopCaptureLog;

@end
