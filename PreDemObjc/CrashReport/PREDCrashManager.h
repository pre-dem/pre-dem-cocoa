//
//  PREDCrashManager.h
//  PreDemObjc
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDChannel.h"

@interface PREDCrashManager : NSObject

@property (nonatomic, assign, getter=isOnDeviceSymbolicationEnabled) BOOL enableOnDeviceSymbolication;

- (instancetype)initWithChannel:(PREDChannel *)channel;

- (void)startManager;

- (void)stopManager;

@end
