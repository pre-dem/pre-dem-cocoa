//
//  PREDHTTPMonitorModel.h
//  PreDemCocoa
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDBaseModel.h"

@interface PREDHTTPMonitorModel : PREDBaseModel

@property(nonatomic, strong) NSString *domain;
@property(nonatomic, strong) NSString *path;
@property(nonatomic, strong) NSString *query;
@property(nonatomic, strong) NSString *method;
@property(nonatomic, strong) NSString *host_ip;
@property(nonatomic, assign) NSInteger status_code;
@property(nonatomic, assign) UInt64 start_timestamp;
@property(nonatomic, assign) UInt64 response_time_stamp;
@property(nonatomic, assign) UInt64 end_timestamp;
@property(nonatomic, assign) NSUInteger dns_time;
@property(nonatomic, assign) NSInteger data_length;
@property(nonatomic, assign) NSInteger network_error_code;
@property(nonatomic, strong) NSString *network_error_msg;

@end
