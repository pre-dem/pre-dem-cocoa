//
//  PREDManagerPrivate.h
//  PreDemObjc
//
//  Created by Troy on 2017/6/27.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#ifndef PREDManagerPrivate_h
#define PREDManagerPrivate_h

#import "PREDManager.h"
#import "PREDConfigManager.h"
#import "PREDNetworkClient.h"

@interface PREDManager ()
<
PREDConfigManagerDelegate
>

+ (PREDManager *_Nonnull)sharedPREDManager;

@property (nonatomic, strong, nonnull) PREDNetworkClient *networkClient;

@property (nonatomic, getter = isCrashManagerDisabled) BOOL disableCrashManager;

@property (nonatomic, getter = isHttpMonitorDisabled) BOOL disableHttpMonitor;

@property (nonatomic, getter = isLagMonitorDisabled) BOOL disableLagMonitor;

@end

#endif /* PREDManagerPrivate_h */
