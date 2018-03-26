//
//  PREDEnums.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDNetDiagResult.h"
#import <CocoaLumberjack/CocoaLumberjack.h>

/**
 *  log 级别，用于过滤 log
 */
typedef NS_ENUM(NSUInteger, PREDLogLevel) {
    /**
     *  过滤掉所有 log
     */
            PREDLogLevelOff = DDLogLevelOff,

    /**
     *  仅打印 error 级别的 log
     */
            PREDLogLevelError = DDLogLevelError,

    /**
     *  打印 Error 及 warning 级别的 log
     */
            PREDLogLevelWarning = DDLogLevelWarning,

    /**
     *  打印 Error, warning 及 info 级别的 log
     */
            PREDLogLevelInfo = DDLogLevelInfo,

    /**
     *  打印 Error, warning, info 及 debug 级别的 log
     */
            PREDLogLevelDebug = DDLogLevelDebug,

    /**
     *  打印 Error, warning, info, debug 以及 verbose 级别的 log
     */
            PREDLogLevelVerbose = DDLogLevelVerbose,

    /**
     *  打印所有级别的 log
     */
            PREDLogLevelAll = DDLogLevelAll
};

/**
 *  Flag 用于标明单条 log 的级别，与 Level 搭配使用过滤 log
 */
typedef NS_OPTIONS(NSUInteger, PREDLogFlag) {
    /**
     *  0...00001 PREDLogFlagError
     */
            PREDLogFlagError = (1 << 0),

    /**
     *  0...00010 PREDLogFlagWarning
     */
            PREDLogFlagWarning = (1 << 1),

    /**
     *  0...00100 PREDLogFlagInfo
     */
            PREDLogFlagInfo = (1 << 2),

    /**
     *  0...01000 PREDLogFlagDebug
     */
            PREDLogFlagDebug = (1 << 3),

    /**
     *  0...10000 PREDLogFlagVerbose
     */
            PREDLogFlagVerbose = (1 << 4)
};

/**
 *  网络诊断结果返回 block
 */
typedef void (^PREDNetDiagCompleteHandler)(PREDNetDiagResult *_Nonnull result);

/**
 *  sdk 启动结果返回 block
 */
typedef void (^PREDStartCompleteHandler)(BOOL succeess, NSError *_Nullable error);
