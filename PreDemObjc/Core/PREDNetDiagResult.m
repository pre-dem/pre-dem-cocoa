//
//  PREDNetDiagResult.m
//  PreDemObjc
//
//  Created by WangSiyu on 25/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDNetDiagResult.h"
#import "PREDManagerPrivate.h"
#import "PREDHelper.h"

#define PREDTotalResultNeeded   5
#define PREDSendRetryInterval   10
#define PREDSendMaxRetryTimes   5

@interface PREDNetDiagResult ()

@property (nonatomic, assign) NSInteger completedCount;
@property (nonatomic, assign) NSInteger retryTimes;
@property (nonatomic, strong) NSLock *lock;
@property (nonatomic, copy) PREDNetDiagCompleteHandler complete;
@property (nonatomic, strong) NSString *appKey;
@property (nonatomic, strong) PREDNetworkClient *client;

@end

@implementation PREDNetDiagResult

- (instancetype)initWithAppKey:(NSString *)appKey complete:(PREDNetDiagCompleteHandler)complete netClient:(PREDNetworkClient *)client {
    if (self = [super init]) {
        self.completedCount = 0;
        self.retryTimes = 0;
        self.lock = [NSLock new];
        self.complete = complete;
        self.appKey = appKey;
        self.client = client;
    }
    return self;
}

- (void)gotTcpResult:(QNNTcpPingResult *)r {
    self.tcp_code = r.code;
    self.tcp_ip = r.ip;
    self.tcp_max_time = r.maxTime;
    self.tcp_min_time = r.minTime;
    self.tcp_avg_time = r.avgTime;
    self.tcp_loss = r.loss;
    self.tcp_count = r.count;
    self.tcp_total_time = r.totalTime;
    self.tcp_stddev = r.stddev;
    [self checkAndSend];
}

- (void)gotPingResult:(QNNPingResult *)r {
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
    [self checkAndSend];
}

- (void)gotHttpResult:(QNNHttpResult *)r {
    self.http_code = r.code;
    self.http_ip = r.ip;
    self.http_duration = r.duration;
    self.http_body_size = r.body.length;
    [self checkAndSend];
}

- (void)gotTrResult:(QNNTraceRouteResult *)r {
    self.tr_code = r.code;
    self.tr_ip = r.ip;
    self.tr_content = r.content;
    [self checkAndSend];
}

- (void)gotNsLookupResult:(NSArray<QNNRecord *> *) r {
    NSMutableString *recordString = [[NSMutableString alloc] initWithCapacity:30];
    for (QNNRecord *record in r) {
        [recordString appendFormat:@"%@\t", record.value];
        [recordString appendFormat:@"%d\t", record.ttl];
        [recordString appendFormat:@"%d\n", record.type];
    }
    self.dns_records = recordString;
    [self checkAndSend];
}

- (NSDictionary *)toDic {
    return [PREDHelper getObjectData:self];
}

- (void)checkAndSend {
    [self.lock lock];
    self.completedCount++;
    if (self.completedCount == PREDTotalResultNeeded) {
        [self.lock unlock];
        [self generateResultID];
        self.complete(self);
        [self sendReport:self.appKey];
    } else {
        [self.lock unlock];
    }
}

- (void)generateResultID {
    self.result_id = [PREDHelper MD5:[NSString stringWithFormat:@"%f%@%@%@", [[NSDate date] timeIntervalSince1970], self.ping_ip, self.tr_content, self.dns_records]];
}

- (void)sendReport:(NSString *)appKey {
    __weak typeof(self) wSelf = self;
    [_client postPath:@"net-diags/i" parameters:[self toDic] completion:^(PREDHTTPOperation *operation, NSData *data, NSError *error) {
        __strong typeof(wSelf) strongSelf = wSelf;
        if ((error || operation.response.statusCode != 200) && strongSelf.retryTimes < PREDSendMaxRetryTimes) {
            strongSelf.retryTimes ++;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PREDSendRetryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [strongSelf sendReport:appKey];
            });
        }
    }];
}

@end
