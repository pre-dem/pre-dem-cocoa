//
//  PREDNetDiagResult.h
//  PreDemCocoa
//
//  Created by WangSiyu on 25/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDBaseModel.h"

/**
 * 网络诊断结果对象
 */
@interface PREDNetDiagResult: PREDBaseModel

/**
 * 结果 id，用于唯一标识网络诊断结果以便检索
 */
@property (nonatomic, nullable, strong) NSString *result_id;

/**
 * ping 返回的 code
 */
@property (nonatomic, assign) NSInteger ping_code;

/**
 * 实际 ping 操作的对端 ip
 */
@property (nonatomic, nullable, strong) NSString* ping_ip;

/**
 * ping 发送的数据包大小
 */
@property (nonatomic, assign) NSUInteger ping_size;

/**
 * ping 操作的 rtt 最大值
 */
@property (nonatomic, assign) NSTimeInterval ping_max_rtt;

/**
 * ping 操作的 rtt 最小值
 */
@property (nonatomic, assign) NSTimeInterval ping_min_rtt;

/**
 * ping 操作的 rtt 平均值
 */
@property (nonatomic, assign) NSTimeInterval ping_avg_rtt;

/**
 * ping 操作的失败次数
 */
@property (nonatomic, assign) NSInteger ping_loss;

/**
 * ping 操作的总数
 */
@property (nonatomic, assign) NSInteger ping_count;

/**
 * ping 操作的总耗时
 */
@property (nonatomic, assign) NSTimeInterval ping_total_time;

/**
 * ping 操作 rtt 的标准差
 */
@property (nonatomic, assign) NSTimeInterval ping_stddev;

/**
 * tcp 建联返回的 code
 */
@property (nonatomic, assign) NSInteger tcp_code;

/**
 * tcp 建联的对端 ip
 */
@property (nonatomic, nullable, strong) NSString* tcp_ip;

/**
 * tcp 建联时间最大值
 */
@property (nonatomic, assign) NSTimeInterval tcp_max_time;

/**
 * tcp 建联时间最小值
 */
@property (nonatomic, assign) NSTimeInterval tcp_min_time;

/**
 * tcp 建联时间平均值
 */
@property (nonatomic, assign) NSTimeInterval tcp_avg_time;

/**
 * tcp 建联失败次数
 */
@property (nonatomic, assign) NSInteger tcp_loss;

/**
 * tcp 建联总次数
 */
@property (nonatomic, assign) NSInteger tcp_count;

/**
 * tcp 建联总时间
 */
@property (nonatomic, assign) NSTimeInterval tcp_total_time;

/**
 * tcp 建联时间标准差
 */
@property (nonatomic, assign) NSTimeInterval tcp_stddev;

/**
 * traceroute 操作返回的 code
 */
@property (nonatomic, assign) NSInteger tr_code;

/**
 * traceroute 操作的对端 ip
 */
@property (nonatomic, nullable, strong) NSString* tr_ip;

/**
 * traceroute 操作的结果内容
 */
@property (nonatomic, nullable, strong) NSString* tr_content;

/**
 * dns 查询结果集
 */
@property (nonatomic, nullable, strong) NSString* dns_records;

/**
 * http 请求返回的 code
 */
@property (nonatomic, assign) NSInteger http_code;

/**
 * http 请求的对端 ip
 */
@property (nonatomic, nullable, strong) NSString* http_ip;

/**
 * http 请求的耗时
 */
@property (nonatomic, assign) NSTimeInterval http_duration;

/**
 * http 请求的 body 大小
 */
@property (nonatomic, assign) NSInteger http_body_size;

@end
