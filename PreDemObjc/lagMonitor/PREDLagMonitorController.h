//
//  PREDLagMonitorController.h
//  Pods
//
//  Created by WangSiyu on 06/07/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDChannel.h"

@interface PREDLagMonitorController : NSObject

- (instancetype)initWithChannel:(PREDChannel *)channel;

- (void)startMonitor;
- (void)endMonitor;

@end
