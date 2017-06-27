//
//  PREDNetDiag.m
//  Pods
//
//  Created by WangSiyu on 24/05/2017.
//
//

#import "PREDNetDiag.h"
#import "QNNetDiag.h"
#import "PREDNetDiagResult.h"
#import "PREDNetDiagResultPrivate.h"

@implementation PREDNetDiag

+ (void)diagnose:(NSString *)host
          appKey:(NSString *)appKey
        complete:(PREDNetDiagCompleteHandler)complete {
    PREDNetDiagResult *result = [[PREDNetDiagResult alloc] initWithAppKey:appKey complete:complete];
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
