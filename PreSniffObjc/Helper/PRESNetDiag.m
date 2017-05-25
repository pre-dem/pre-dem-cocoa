//
//  PRESNetDiag.m
//  Pods
//
//  Created by WangSiyu on 24/05/2017.
//
//

#import "PRESNetDiag.h"
#import "QNNetDiag.h"

#define PRESSendRetryInterval   10
#define PRESNetDiagDomain       @"http://localhost:8080"
#define PRESNetDiagPath         @"/v1/net_diag"

@implementation PRESNetDiag

+ (void)diagnose:(NSString *)host
        complete:(PRESNetDiagCompleteHandler)complete
          appKey:(NSString *)appKey {
    NSUInteger operationCount = 5;
    __block NSUInteger completedCount = 0;
    PRESNetDiagResult *result = [PRESNetDiagResult new];
    [QNNPing start:host size:64 output:nil complete:^(QNNPingResult *r) {
        completedCount ++;
        result.ping_code = r.code;
        result.ping_ip = r.ip;
        result.ping_size = r.size;
        result.ping_max_rtt = r.maxRtt;
        result.ping_min_rtt = r.minRtt;
        result.ping_avg_rtt = r.avgRtt;
        result.ping_loss = r.loss;
        result.ping_count = r.count;
        result.ping_total_time = r.totalTime;
        result.ping_stddev = r.stddev;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result appKey:appKey];
        }
    }];
    [QNNTcpPing start:host output:nil complete:^(QNNTcpPingResult *r) {
        completedCount ++;
        result.tcp_code = r.code;
        result.tcp_ip = r.ip;
        result.tcp_max_time = r.maxTime;
        result.tcp_min_time = r.minTime;
        result.tcp_avg_time = r.avgTime;
        result.tcp_loss = r.loss;
        result.tcp_count = r.count;
        result.tcp_total_time = r.totalTime;
        result.tcp_stddev = r.stddev;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result appKey:appKey];
        }
    }];
    [QNNTraceRoute start:host output:nil complete:^(QNNTraceRouteResult *r) {
        completedCount++;
        result.tr_code = r.code;
        result.tr_ip = r.ip;
        result.tr_content = r.content;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result appKey:appKey];
        }
    }];
    [QNNNslookup start:host output:nil complete:^(NSArray *r) {
        completedCount++;
        NSMutableString *recordString = [[NSMutableString alloc] initWithCapacity:30];
        for (QNNRecord *record in r) {
            [recordString appendFormat:@"%@\t", record.value];
            [recordString appendFormat:@"%d\t", record.ttl];
            [recordString appendFormat:@"%d\n", record.type];
        }
        result.dns_records = recordString;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result appKey:appKey];
        }
    }];
    [QNNHttp start:host output:nil complete:^(QNNHttpResult *r) {
        completedCount++;
        result.http_code = r.code;
        result.http_ip = r.ip;
        result.http_duration = r.duration;
        result.http_body_size = r.body.length;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result appKey:appKey];
        }
    }];
}

+ (void)sendReport:(PRESNetDiagResult *)result appKey:(NSString *)appKey {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@/%@", PRESNetDiagDomain, PRESNetDiagPath, appKey]]];
    request.HTTPMethod = @"POST";
    NSError *err;
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:[result toDic] options:0 error:&err];
    if (err) {
        return;
    }
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PRESInternalRequest"
                     inRequest:request];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode != 201) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PRESSendRetryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [PRESNetDiag sendReport:result  appKey:appKey];
            });
        }
    }] resume];
}

@end
