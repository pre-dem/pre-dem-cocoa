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
 *  Log levels are used to filter out logs. Used together with flags.
 */
typedef NS_ENUM(NSUInteger, PREDLogLevel) {
    /**
     *  No logs
     */
    PREDLogLevelOff = DDLogLevelOff,
    
    /**
     *  Error logs only
     */
    PREDLogLevelError = DDLogLevelError,
    
    /**
     *  Error and warning logs
     */
    PREDLogLevelWarning = DDLogLevelWarning,
    
    /**
     *  Error, warning and info logs
     */
    PREDLogLevelInfo = DDLogLevelInfo,
    
    /**
     *  Error, warning, info and debug logs
     */
    PREDLogLevelDebug = DDLogLevelDebug,
    
    /**
     *  Error, warning, info, debug and verbose logs
     */
    PREDLogLevelVerbose = DDLogLevelVerbose,
    
    /**
     *  All logs (1...11111)
     */
    PREDLogLevelAll = DDLogLevelAll
};

typedef void (^PREDNetDiagCompleteHandler)(PREDNetDiagResult* result);

typedef NSString *(^PREDLogMessageProvider)(void);

typedef void (^PREDLogHandler)(PREDLogMessageProvider messageProvider, PREDLogLevel logLevel, const char *file, const char *function, uint line);

#endif /* PreDemObjc_Enums_h */
