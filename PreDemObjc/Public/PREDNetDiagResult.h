//
//  PREDNetDiagResult.h
//  PreDemObjc
//
//  Created by WangSiyu on 25/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PREDNetDiagResult : NSObject

@property (nonatomic, nullable, strong) NSString *app_bundle_id;
@property (nonatomic, nullable, strong) NSString *app_name;
@property (nonatomic, nullable, strong) NSString *app_version;
@property (nonatomic, nullable, strong) NSString *device_model;
@property (nonatomic, nullable, strong) NSString *os_platform;
@property (nonatomic, nullable, strong) NSString *os_version;
@property (nonatomic, nullable, strong) NSString *sdk_version;
@property (nonatomic, nullable, strong) NSString *sdk_id;
@property (nonatomic, nullable, strong) NSString *device_id;
@property (nonatomic, nullable, strong) NSString *tag;

@property (nonatomic, nullable, strong) NSString *result_id;

@property (nonatomic, assign) NSInteger ping_code;
@property (nonatomic, nullable, strong) NSString* ping_ip;
@property (nonatomic, assign) NSUInteger ping_size;
@property (nonatomic, assign) NSTimeInterval ping_max_rtt;
@property (nonatomic, assign) NSTimeInterval ping_min_rtt;
@property (nonatomic, assign) NSTimeInterval ping_avg_rtt;
@property (nonatomic, assign) NSInteger ping_loss;
@property (nonatomic, assign) NSInteger ping_count;
@property (nonatomic, assign) NSTimeInterval ping_total_time;
@property (nonatomic, assign) NSTimeInterval ping_stddev;

@property (nonatomic, assign) NSInteger tcp_code;
@property (nonatomic, nullable, strong) NSString* tcp_ip;
@property (nonatomic, assign) NSTimeInterval tcp_max_time;
@property (nonatomic, assign) NSTimeInterval tcp_min_time;
@property (nonatomic, assign) NSTimeInterval tcp_avg_time;
@property (nonatomic, assign) NSInteger tcp_loss;
@property (nonatomic, assign) NSInteger tcp_count;
@property (nonatomic, assign) NSTimeInterval tcp_total_time;
@property (nonatomic, assign) NSTimeInterval tcp_stddev;

@property (nonatomic, assign) NSInteger tr_code;
@property (nonatomic, nullable, strong) NSString* tr_ip;
@property (nonatomic, nullable, strong) NSString* tr_content;

@property (nonatomic, nullable, strong) NSString* dns_records;

@property (nonatomic, assign) NSInteger http_code;
@property (nonatomic, nullable, strong) NSString* http_ip;
@property (nonatomic, assign) NSTimeInterval http_duration;
@property (nonatomic, assign) NSInteger http_body_size;

@end

NS_ASSUME_NONNULL_END
