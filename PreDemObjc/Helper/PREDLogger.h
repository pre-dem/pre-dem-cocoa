//
//  PREDLogger.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"

#ifdef LOG_LEVEL_DEF
    #undef LOG_LEVEL_DEF
#endif
#define LOG_LEVEL_DEF       predLogLevel

static const DDLogLevel predLogLevel = DDLogLevelAll;

#define PREDLogError(format, ...)   DDLogError(format, ##__VA_ARGS__)
#define PREDLogWarn(format, ...)    DDLogWarn(format, ##__VA_ARGS__)
#define PREDLogInfo(format, ...)    DDLogInfo(format, ##__VA_ARGS__)
#define PREDLogDebug(format, ...)   DDLogDebug(format, ##__VA_ARGS__)
#define PREDLogVerbose(format, ...) DDLogVerbose(format, ##__VA_ARGS__)

@interface PREDLogger : NSObject

@property(class, nonatomic, assign) DDLogLevel logLevel;

@end
