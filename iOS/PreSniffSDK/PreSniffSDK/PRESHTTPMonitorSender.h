//
//  PRESHTTPMonitorSender.h
//  PreSniffSDK
//
//  Created by WangSiyu on 28/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PRESHTTPMonitorModel.h"

@interface PRESHTTPMonitorSender : NSObject

+ (instancetype)sharedSender;

- (void)addModel:(PRESHTTPMonitorModel *)model;

@end
