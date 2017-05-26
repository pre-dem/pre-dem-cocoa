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
    NSLock *lock = [NSLock new];
    NSUInteger operationCount = 5;
    __block NSUInteger completedCount = 0;
    PRESNetDiagResult *result = [PRESNetDiagResult new];
    __weak typeof(self) wSelf = self;
    [QNNPing start:host size:64 output:nil complete:^(QNNPingResult *r) {
        __strong typeof(wSelf) strongSelf = wSelf;
        [lock lock];
        completedCount ++;
        [lock unlock];
        [result setPingResult:r];
        if (completedCount == operationCount) {
            complete(result);
            [strongSelf sendReport:result appKey:appKey];
        }
    }];
    [QNNTcpPing start:host output:nil complete:^(QNNTcpPingResult *r) {
        __strong typeof(wSelf) strongSelf = wSelf;
        [lock lock];
        completedCount ++;
        [lock unlock];
        [result setTcpResult:r];
        if (completedCount == operationCount) {
            complete(result);
            [strongSelf sendReport:result appKey:appKey];
        }
    }];
    [QNNTraceRoute start:host output:nil complete:^(QNNTraceRouteResult *r) {
        __strong typeof(wSelf) strongSelf = wSelf;
        [lock lock];
        completedCount++;
        [lock unlock];
        [result setTrResult:r];
        if (completedCount == operationCount) {
            complete(result);
            [strongSelf sendReport:result appKey:appKey];
        }
    }];
    [QNNNslookup start:host output:nil complete:^(NSArray *r) {
        __strong typeof(wSelf) strongSelf = wSelf;
        [lock lock];
        completedCount++;
        [lock unlock];
        [result setNsLookupResult:r];
        if (completedCount == operationCount) {
            complete(result);
            [strongSelf sendReport:result appKey:appKey];
        }
    }];
    [QNNHttp start:host output:nil complete:^(QNNHttpResult *r) {
        __strong typeof(wSelf) strongSelf = wSelf;
        [lock lock];
        completedCount++;
        [lock unlock];
        [result setHttpResult:r];
        if (completedCount == operationCount) {
            complete(result);
            [strongSelf sendReport:result appKey:appKey];
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
        if (error || httpResponse.statusCode != 200) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(PRESSendRetryInterval * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                [PRESNetDiag sendReport:result  appKey:appKey];
            });
        }
    }] resume];
}

@end
