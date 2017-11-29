//
//  PREDLogger.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"

static const DDLogLevel predLogLevel = DDLogLevelAll;

#define PRED_LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [PREDLog log : isAsynchronous                                     \
               level : lvl                                                \
                flag : flg                                                \
             context : ctx                                                \
                file : __FILE__                                           \
            function : fnct                                               \
                line : __LINE__                                           \
                 tag : atag                                               \
              format : (frmt), ## __VA_ARGS__]

#define PRED_LOG_MAYBE(async, lvl, flg, ctx, tag, fnct, frmt, ...) \
        do { if(lvl & flg) PRED_LOG_MACRO(async, lvl, flg, ctx, tag, fnct, frmt, ##__VA_ARGS__); } while(0)

/**
 * 以 error 级别打印 log
 */
#define PREDLogError(frmt, ...)   PRED_LOG_MAYBE(NO,                predLogLevel, DDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 warn 级别打印 log
 */
#define PREDLogWarn(frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 info 级别打印 log
 */
#define PREDLogInfo(frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 debug 级别打印 log
 */
#define PREDLogDebug(frmt, ...)   PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 verbose 级别打印 log
 */
#define PREDLogVerbose(frmt, ...) PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 error 级别打印带有 tag 的 log
 */
#define PREDTagLogError(tag, frmt, ...)   PRED_LOG_MAYBE(NO,                predLogLevel, DDLogFlagError,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 warn 级别打印带有 tag 的 log
 */
#define PREDTagLogWarn(tag, frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagWarning, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 info 级别打印带有 tag 的 log
 */
#define PREDTagLogInfo(tag, frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagInfo,    0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 debug 级别打印带有 tag 的 log
 */
#define PREDTagLogDebug(tag, frmt, ...)   PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagDebug,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 verbose 级别打印带有 tag 的 log
 */
#define PREDTagLogVerbose(tag, frmt, ...) PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, DDLogFlagVerbose, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

@class PREDLog;

@protocol PREDLogDelegate<NSObject>

- (void)log:(PREDLog *_Nonnull)log didReceivedLogMessage:(DDLogMessage *_Nonnull)message formattedLog:(NSString *_Nonnull)formattedLog;

@end

/**
 * logger 核心类，提供日志打印相关接口
 */
@interface PREDLog : DDLog

/**
 * 底层的 DDLog 对象，请勿直接使用
 */
@property(class, nonatomic, readonly, strong, nonnull) PREDLog *sharedInstance;

/**
 * 是否开启控制台打印，当您启动了 PREDManager，控制台打印将自动启动
 */
@property(class, nonatomic, assign) BOOL started;


@property(class, nonatomic, weak, nullable) id<PREDLogDelegate> delegate;

/**
 * 控制台 log 打印的级别
 */
@property(class, nonatomic, assign) PREDLogLevel ttyLogLevel;

/**
 * 开始采集 log 上报到服务器，这项和 `started` 属性配置互不影响
 *
 * @param logLevel 采集的 log 级别，例如 PREDLogLevelWarning 将采集 error 及 warn 级别的 log 进行上报
 * @return 是否成功开启 log 采集
 */
+ (BOOL)startCaptureLogWithLevel:(PREDLogLevel)logLevel error:(NSError *_Nullable*_Nullable)error;

/**
 * 停止采集 log 上报到服务器
 */
+ (void)stopCaptureLog;

@end
