//
//  PREDHTTPMonitorModel.h
//  PreDemObjc
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PREDHTTPMonitorModel : NSObject

@property (nonatomic, assign) NSString      *app_bundle_id;
@property (nonatomic, strong) NSString      *app_name;
@property (nonatomic, strong) NSString      *app_version;
@property (nonatomic, strong) NSString      *device_model;
@property (nonatomic, strong) NSString      *os_platform;
@property (nonatomic, strong) NSString      *os_version;
@property (nonatomic, strong) NSString      *os_build;
@property (nonatomic, strong) NSString      *sdk_version;
@property (nonatomic, strong) NSString      *sdk_id;
@property (nonatomic, strong) NSString      *tag;
@property (nonatomic, strong) NSString      *manufacturer;
@property (nonatomic, strong) NSString      *domain;
@property (nonatomic, strong) NSString      *path;
@property (nonatomic, strong) NSString      *method;
@property (nonatomic, strong) NSString      *host_ip;
@property (nonatomic, assign) NSInteger     status_code;
@property (nonatomic, assign) UInt64        start_timestamp;
@property (nonatomic, assign) UInt64        response_time_stamp;
@property (nonatomic, assign) UInt64        end_timestamp;
@property (nonatomic, assign) NSUInteger    dns_time;
@property (nonatomic, assign) NSInteger     data_length;
@property (nonatomic, assign) NSInteger     network_error_code;
@property (nonatomic, strong) NSString      *network_error_msg;

@end
