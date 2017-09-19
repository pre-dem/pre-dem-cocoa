//
//  PREDChannel.m
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import "PREDChannel.h"
#import "PREDLogger.h"
#import "PREDPersistence.h"
#import "PREDSender.h"

#define PREDDefaultMaxBatchSize     50
#define PREDDefaultBatchInterval    15

#define PREDDebugMaxBatchSize       5
#define PREDDebugBatchInterval      3

@implementation PREDChannel {
    PREDPersistence *_persistence;
    NSMutableArray<PREDHTTPMonitorModel *> *_httpMonitorModels;
    NSMutableArray<PREDNetDiagResult *> *_netDiagResults;
    PREDSender *_sender;
}

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl {
    if (self = [super init]) {
        _httpMonitorModels = [NSMutableArray array];
        _persistence = [[PREDPersistence alloc] init];
        _sender = [[PREDSender alloc] initWithPersistence:_persistence baseUrl:baseUrl];
    }
    return self;
}

- (void)sinkHttpMonitorModel:(PREDHTTPMonitorModel *)model {
    [_httpMonitorModels addObject:model];
    if (_httpMonitorModels.count >= PREDDefaultMaxBatchSize) {
        [_persistence persistHttpMonitors:_httpMonitorModels];
    }
    [_httpMonitorModels removeAllObjects];
}

- (void)sinkNetDiag:(PREDNetDiagResult *)netDiag {
    [_netDiagResults addObject:netDiag];
    if (_netDiagResults.count >= PREDDefaultMaxBatchSize) {
        [_persistence persistNetDiagResults:_netDiagResults];
    }
    [_netDiagResults removeAllObjects];
}

- (void)sinkCrashMeta:(PREDCrashMeta *)crashMeta {
    [_persistence persistCrashMeta:crashMeta];
}

- (void)sinkLagMeta:(PREDLagMeta *)lagMeta {
    [_persistence persistLagMeta:lagMeta];
}

- (void)sinkLogMeta:(PREDLogMeta *)logMeta {
    [_persistence persistLogMeta:logMeta];
}

- (void)sinkAppInfo:(PREDAppInfo *)appinfo {
    [_persistence persistAppInfo:appinfo];
}


@end
