//
//  PREDEnums.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#ifndef PreDemObjc_Enums_h
#define PreDemObjc_Enums_h

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
 *  网络诊断结果返回 block
 */
typedef void (^PREDNetDiagCompleteHandler)(PREDNetDiagResult* _Nonnull result);

/**
 *  sdk 启动结果返回 block
 */
typedef void (^PREDStartCompleteHandler)(BOOL succeess, NSError *_Nullable error);

#endif /* PreDemObjc_Enums_h */
