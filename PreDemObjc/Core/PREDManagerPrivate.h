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
#import "PREDCrashManager.h"

@interface PREDManager ()
<
PREDConfigManagerDelegate
>

@property (nonatomic, readonly) PREDEnvironment appEnvironment;

@property (nonatomic, strong) NSString * _Nullable serverURL;

@property (nonatomic, strong, readonly) PREDCrashManager * _Nullable crashManager;

@property (nonatomic, getter = isCrashManagerDisabled) BOOL disableCrashManager;

@property (nonatomic, getter = isHttpMonitorDisabled) BOOL disableHttpMonitor;

+(PREDManager *_Nonnull)sharedPREDManager;

-(nonnull NSString*) baseUrl;

@end

#endif /* PREDManagerPrivate_h */
