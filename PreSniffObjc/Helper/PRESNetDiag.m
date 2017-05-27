//
//  PRESNetDiag.m
//  Pods
//
//  Created by WangSiyu on 24/05/2017.
//
//

#import "PRESNetDiag.h"
#import "QNNetDiag.h"
#import "PRESNetDiagResult.h"

@implementation PRESNetDiag

+ (void)diagnose:(NSString *)host
          appKey:(NSString *)appKey
        complete:(PRESNetDiagCompleteHandler)complete {
    PRESNetDiagResult *result = [[PRESNetDiagResult alloc] initWithAppKey:appKey complete:complete];
    [QNNPing start:host size:64 output:nil complete:^(QNNPingResult *r) {
        [result gotPingResult:r];
    }];
    [QNNTcpPing start:host output:nil complete:^(QNNTcpPingResult *r) {
        [result gotTcpResult:r];
    }];
    [QNNTraceRoute start:host output:nil complete:^(QNNTraceRouteResult *r) {
        [result gotTrResult:r];
    }];
    [QNNNslookup start:host output:nil complete:^(NSArray *r) {
        [result gotNsLookupResult:r];
    }];
    [QNNHttp start:host output:nil complete:^(QNNHttpResult *r) {
        [result gotHttpResult:r];
    }];
}

@end
