//
//  PREDLogger.m
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDLogger.h"
#import "PreDemObjc.h"

static DDLogLevel _logLevel = DDLogLevelAll;

@implementation PREDLogger

+ (void)load {
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:_logLevel];
}

+ (void)setLogLevel:(DDLogLevel)logLevel {
    if (_logLevel == logLevel) {
        return;
    }
    _logLevel = logLevel;
    [DDLog removeLogger:[DDTTYLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance] withLevel:_logLevel];
}

+ (DDLogLevel)logLevel {
    return _logLevel;
}

@end
