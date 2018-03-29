//
//  PREDEnums.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDNetDiagResult.h"

/**
 *  log 级别，用于过滤 log
 */
typedef NS_ENUM(NSUInteger, PREDLogLevel) {
    /**
     *  过滤掉所有 log
     */
            PREDLogLevelOff = 0,

    /**
     *  仅打印 error 级别的 log
     */
            PREDLogLevelError = 1 << 0,

    /**
     *  打印 Error 及 warning 级别的 log
     */
            PREDLogLevelWarning = 1 << 1,

    /**
     *  打印 Error, warning 及 info 级别的 log
     */
            PREDLogLevelInfo = 1 << 2,

    /**
     *  打印 Error, warning, info 及 debug 级别的 log
     */
            PREDLogLevelDebug = 1 << 3,

    /**
     *  打印 Error, warning, info, debug 以及 verbose 级别的 log
     */
            PREDLogLevelVerbose = 1 << 4,

    /**
     *  打印所有级别的 log
     */
            PREDLogLevelAll = NSUIntegerMax
};

typedef NSString *_Nullable(^PREDLogMessageProvider)(void);

typedef void (^PREDLogHandler)(PREDLogMessageProvider _Nullable messageProvider, PREDLogLevel logLevel, const char * _Nullable file, const char * _Nonnull function, uint line);

/**
 *  网络诊断结果返回 block
 */
typedef void (^PREDNetDiagCompleteHandler)(PREDNetDiagResult *_Nonnull result);

/**
 *  sdk 启动结果返回 block
 */
typedef void (^PREDStartCompleteHandler)(BOOL succeess, NSError *_Nullable error);
