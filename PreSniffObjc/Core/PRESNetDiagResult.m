//
//  PRESNetDiagResult.m
//  Pods
//
//  Created by WangSiyu on 25/05/2017.
//
//

#import "PRESNetDiagResult.h"
#import "PRESUtilities.h"

@implementation PRESNetDiagResult

- (NSDictionary *)toDic {
    return [PRESUtilities getObjectData:self];
}

- (void)setTcpResult:(QNNTcpPingResult *)r {
    self.tcp_code = r.code;
    self.tcp_ip = r.ip;
    self.tcp_max_time = r.maxTime;
    self.tcp_min_time = r.minTime;
    self.tcp_avg_time = r.avgTime;
    self.tcp_loss = r.loss;
    self.tcp_count = r.count;
    self.tcp_total_time = r.totalTime;
    self.tcp_stddev = r.stddev;
}

- (void)setPingResult:(QNNPingResult *)r {
    self.ping_code = r.code;
    self.ping_ip = r.ip;
    self.ping_size = r.size;
    self.ping_max_rtt = r.maxRtt;
    self.ping_min_rtt = r.minRtt;
    self.ping_avg_rtt = r.avgRtt;
    self.ping_loss = r.loss;
    self.ping_count = r.count;
    self.ping_total_time = r.totalTime;
    self.ping_stddev = r.stddev;
}

- (void)setHttpResult:(QNNHttpResult *)r {
    self.http_code = r.code;
    self.http_ip = r.ip;
    self.http_duration = r.duration;
    self.http_body_size = r.body.length;
}

- (void)setTrResult:(QNNTraceRouteResult *)r {
    self.tr_code = r.code;
    self.tr_ip = r.ip;
    self.tr_content = r.content;
}

- (void)setNsLookupResult:(NSArray<QNNRecord *> *) r {
    NSMutableString *recordString = [[NSMutableString alloc] initWithCapacity:30];
    for (QNNRecord *record in r) {
        [recordString appendFormat:@"%@\t", record.value];
        [recordString appendFormat:@"%d\t", record.ttl];
        [recordString appendFormat:@"%d\n", record.type];
    }
    self.dns_records = recordString;
}

@end
