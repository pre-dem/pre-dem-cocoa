//
//  PREDNetDiagResult.m
//  PreDemObjc
//
//  Created by WangSiyu on 25/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDNetDiagResult.h"
#import "PREDManagerPrivate.h"
#import "PREDNetDiagResultPrivate.h"
#import "PREDHelper.h"
#import "PREDLogger.h"
#import "QNNetDiag.h"

#define PREDTotalResultNeeded   5

@implementation PREDNetDiagResult {
    NSInteger _completedCount;
    NSLock *_lock;
    PREDNetDiagCompleteHandler _complete;
    PREDChannel *_channel;
}

- (NSString *)description {
    return [PREDHelper getObjectData:self].description;
}

- (instancetype)initWithComplete:(PREDNetDiagCompleteHandler)complete channel:(PREDChannel *)channel {
    if (self = [super init]) {
        _completedCount = 0;
        _lock = [NSLock new];
        _complete = complete;
        _channel = channel;
    }
    return self;
}

- (void)gotTcpResult:(QNNTcpPingResult *)r {
    _tcp_code = r.code;
    _tcp_ip = r.ip;
    _tcp_max_time = r.maxTime;
    _tcp_min_time = r.minTime;
    _tcp_avg_time = r.avgTime;
    _tcp_loss = r.loss;
    _tcp_count = r.count;
    _tcp_total_time = r.totalTime;
    _tcp_stddev = r.stddev;
    [self checkAndSend];
}

- (void)gotPingResult:(QNNPingResult *)r {
    _ping_code = r.code;
    _ping_ip = r.ip;
    _ping_size = r.size;
    _ping_max_rtt = r.maxRtt;
    _ping_min_rtt = r.minRtt;
    _ping_avg_rtt = r.avgRtt;
    _ping_loss = r.loss;
    _ping_count = r.count;
    _ping_total_time = r.totalTime;
    _ping_stddev = r.stddev;
    [self checkAndSend];
}

- (void)gotHttpResult:(QNNHttpResult *)r {
    _http_code = r.code;
    _http_ip = r.ip;
    _http_duration = r.duration;
    _http_body_size = r.body.length;
    [self checkAndSend];
}

- (void)gotTrResult:(QNNTraceRouteResult *)r {
    _tr_code = r.code;
    _tr_ip = r.ip;
    _tr_content = r.content;
    [self checkAndSend];
}

- (void)gotNsLookupResult:(NSArray<QNNRecord *> *) r {
    NSMutableString *recordString = [[NSMutableString alloc] initWithCapacity:30];
    for (QNNRecord *record in r) {
        [recordString appendFormat:@"%@\t", record.value];
        [recordString appendFormat:@"%d\t", record.ttl];
        [recordString appendFormat:@"%d\n", record.type];
    }
    _dns_records = recordString;
    [self checkAndSend];
}

- (void)checkAndSend {
    [_lock lock];
    _completedCount++;
    if (_completedCount == PREDTotalResultNeeded) {
        [_lock unlock];
        [self generateResultID];
        _complete(self);
        [_channel sinkNetDiag:self];
    } else {
        [_lock unlock];
    }
}

- (void)generateResultID {
    _result_id = [PREDHelper MD5:[NSString stringWithFormat:@"%f%@%@%@", [[NSDate date] timeIntervalSince1970], _ping_ip, _tr_content, _dns_records]];
}

@end
