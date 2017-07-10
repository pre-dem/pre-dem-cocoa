//
//  PREDHTTPMonitorSender.h
//  PreDemObjc
//
//  Created by WangSiyu on 28/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDHTTPMonitorModel.h"
#import "PREDNetworkClient.h"

@interface PREDHTTPMonitorSender : NSObject

@property (nonatomic, assign, getter=isEnabled) BOOL enable;

- (instancetype)initWithNetworkClient:(PREDNetworkClient *)client;

- (void)addModel:(PREDHTTPMonitorModel *)model;

@end
