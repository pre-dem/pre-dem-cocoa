//
//  PREDHTTPMonitorModel.m
//  PreDemObjc
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDHTTPMonitorModel.h"
#import "PREDHelper.h"
#import <objc/runtime.h>
#import "PREDConstants.h"

@implementation PREDHTTPMonitorModel

- (instancetype)init {
    return [self initWithName:HttpMonitorEventName type:AutoCapturedEventType];
}

@end
