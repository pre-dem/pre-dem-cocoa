//
//  PREDLogger.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"

static const PREDLogLevel predLogLevel = PREDLogLevelAll;

#define PRED_LOG_MACRO(isAsynchronous, lvl, flg, ctx, atag, fnct, frmt, ...) \
        [PREDLogger log : isAsynchronous                                     \
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
#define PREDLogError(frmt, ...)   PRED_LOG_MAYBE(NO,                predLogLevel, PREDLogFlagError,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 warn 级别打印 log
 */
#define PREDLogWarn(frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagWarning, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 info 级别打印 log
 */
#define PREDLogInfo(frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagInfo,    0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 debug 级别打印 log
 */
#define PREDLogDebug(frmt, ...)   PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagDebug,   0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 verbose 级别打印 log
 */
#define PREDLogVerbose(frmt, ...) PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagVerbose, 0, nil, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 error 级别打印带有 tag 的 log
 */
#define PREDTagLogError(tag, frmt, ...)   PRED_LOG_MAYBE(NO,                predLogLevel, PREDLogFlagError,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 warn 级别打印带有 tag 的 log
 */
#define PREDTagLogWarn(tag, frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagWarning, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 info 级别打印带有 tag 的 log
 */
#define PREDTagLogInfo(tag, frmt, ...)    PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagInfo,    0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 debug 级别打印带有 tag 的 log
 */
#define PREDTagLogDebug(tag, frmt, ...)   PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagDebug,   0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * 以 verbose 级别打印带有 tag 的 log
 */
#define PREDTagLogVerbose(tag, frmt, ...) PRED_LOG_MAYBE(LOG_ASYNC_ENABLED, predLogLevel, PREDLogFlagVerbose, 0, tag, __PRETTY_FUNCTION__, frmt, ##__VA_ARGS__)

/**
 * logger 核心类，提供日志打印相关接口
 */
@interface PREDLogger : NSObject

/**
 * 原始打印方法
 *
 * 此方法主要供 log 的宏使用
 * 建议您使用更加易用的宏来打印，而非此方法
 *
 *  @param asynchronous 如果此条 log 异步打印则为 YES, 如果你希望强制同步打印则为 NO
 *  @param level        log 的级别
 *  @param flag         log 的标志
 *  @param context      log 的 context (如果已经定义的话)
 *  @param file         产生打印请求的文件
 *  @param function     产生打印请求的函数
 *  @param line         产生打印请求的代码行数
 *  @param tag          请求需要附加的 tag
 *  @param format       格式化打印字符串
 */
+ (void)log:(BOOL)asynchronous
      level:(PREDLogLevel)level
       flag:(PREDLogFlag)flag
    context:(NSInteger)context
       file:(const char *)file
   function:(const char *)function
       line:(NSUInteger)line
        tag:(id)tag
     format:(NSString *)format, ... NS_FORMAT_FUNCTION(9,10);

/**
 * 是否开启控制台打印，当您启动了 PREDManager，控制台打印将自动启动
 */
@property(class, nonatomic, assign) BOOL started;

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
+ (BOOL)startCaptureLogWithLevel:(PREDLogLevel)logLevel error:(NSError **)error;

/**
 * 停止采集 log 上报到服务器
 */
+ (void)stopCaptureLog;

@end
