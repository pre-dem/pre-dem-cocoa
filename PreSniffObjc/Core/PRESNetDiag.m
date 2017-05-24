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
        complete:(PRESNetDiagCompleteHandler)complete {
    NSUInteger operationCount = 5;
    __block NSUInteger completedCount = 0;
    PRESNetDiagResult *result = [PRESNetDiagResult new];
    [QNNPing start:host size:64 output:nil complete:^(QNNPingResult *r) {
        completedCount ++;
        result.ping_code = r.code;
        result.ping_ip = r.ip;
        result.ping_size = r.size;
        result.ping_maxRtt = r.maxRtt;
        result.ping_minRtt = r.minRtt;
        result.ping_avgRtt = r.avgRtt;
        result.ping_loss = r.loss;
        result.ping_count = r.count;
        result.ping_totalTime = r.totalTime;
        result.ping_stddev = r.stddev;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result];
        }
    }];
    [QNNTcpPing start:host output:nil complete:^(QNNTcpPingResult *r) {
        completedCount ++;
        result.tcp_code = r.code;
        result.tcp_ip = r.ip;
        result.tcp_maxTime = r.maxTime;
        result.tcp_minTime = r.minTime;
        result.tcp_avgTime = r.avgTime;
        result.tcp_loss = r.loss;
        result.tcp_count = r.count;
        result.tcp_totalTime = r.totalTime;
        result.tcp_stddev = r.stddev;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result];
        }
    }];
    [QNNTraceRoute start:host output:nil complete:^(QNNTraceRouteResult *r) {
        completedCount++;
        result.tr_code = r.code;
        result.tr_ip = r.ip;
        result.tr_content = r.content;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result];
        }
    }];
    [QNNNslookup start:host output:nil complete:^(NSArray *r) {
        completedCount++;
        result.dns_records = r;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result];
        }
    }];
    [QNNHttp start:host output:nil complete:^(QNNHttpResult *r) {
        completedCount++;
        result.http_code = r.code;
        result.http_ip = r.ip;
        result.http_duration = r.duration;
        result.http_headers = r.headers;
        result.http_body = r.body;
        if (completedCount == operationCount) {
            complete(result);
            [self sendReport:result];
        }
    }];
}

+ (void)sendReport:(PRESNetDiagResult *)result {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", PRESNetDiagDomain, PRESNetDiagPath]]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = nil;
    [request addValue:@"application/x-gzip" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
    [NSURLProtocol setProperty:@YES
                        forKey:@"PRESInternalRequest"
                     inRequest:request];
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        if (error || httpResponse.statusCode != 201) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PRESSendRetryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [PRESNetDiag sendReport:result];
            });
        }
    }] resume];
}

@end
