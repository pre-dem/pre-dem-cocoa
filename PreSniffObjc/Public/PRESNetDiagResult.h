//
//  PRESNetDiagResult.h
//  Pods
//
//  Created by WangSiyu on 25/05/2017.
//
//

#import <Foundation/Foundation.h>
#import "QNNetDiag.h"
#import "PreSniffObjc.h"

@interface PRESNetDiagResult : NSObject

@property (nonatomic, strong) NSString *result_id;

@property (nonatomic, assign) NSInteger ping_code;
@property (nonatomic, strong) NSString* ping_ip;
@property (nonatomic, assign) NSUInteger ping_size;
@property (nonatomic, assign) NSTimeInterval ping_max_rtt;
@property (nonatomic, assign) NSTimeInterval ping_min_rtt;
@property (nonatomic, assign) NSTimeInterval ping_avg_rtt;
@property (nonatomic, assign) NSInteger ping_loss;
@property (nonatomic, assign) NSInteger ping_count;
@property (nonatomic, assign) NSTimeInterval ping_total_time;
@property (nonatomic, assign) NSTimeInterval ping_stddev;

@property (nonatomic, assign) NSInteger tcp_code;
@property (nonatomic, strong) NSString* tcp_ip;
@property (nonatomic, assign) NSTimeInterval tcp_max_time;
@property (nonatomic, assign) NSTimeInterval tcp_min_time;
@property (nonatomic, assign) NSTimeInterval tcp_avg_time;
@property (nonatomic, assign) NSInteger tcp_loss;
@property (nonatomic, assign) NSInteger tcp_count;
@property (nonatomic, assign) NSTimeInterval tcp_total_time;
@property (nonatomic, assign) NSTimeInterval tcp_stddev;

@property (nonatomic, assign) NSInteger tr_code;
@property (nonatomic, strong) NSString* tr_ip;
@property (nonatomic, strong) NSString* tr_content;

@property (nonatomic, strong) NSString* dns_records;

@property (nonatomic, assign) NSInteger http_code;
@property (nonatomic, strong) NSString* http_ip;
@property (nonatomic, assign) NSTimeInterval http_duration;
@property (nonatomic, assign) NSInteger http_body_size;

@end
