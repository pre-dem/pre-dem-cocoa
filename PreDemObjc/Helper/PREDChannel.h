//
//  PREDChannel.h
//  Pods
//
//  Created by 王思宇 on 14/09/2017.
//
//

#import <Foundation/Foundation.h>
#import "PREDHTTPMonitorModel.h"
#import "PREDCrashMeta.h"
#import "PREDLagMeta.h"
#import "PREDLogMeta.h"
#import "PREDNetDiagResult.h"

@interface PREDChannel : NSObject

@property (nonatomic) NSUInteger maxBatchSize;

- (instancetype)initWithBaseUrl:(NSURL *)baseUrl;
- (void)sinkHttpMonitorModel:(PREDHTTPMonitorModel *)model;
- (void)sinkNetDiag:(PREDNetDiagResult *)netDiag;
- (void)sinkCrashMeta:(PREDCrashMeta *)crashMeta;
- (void)sinkLagMeta:(PREDLagMeta *)lagMeta;
- (void)sinkLogMeta:(PREDLogMeta *)logMeta;

@end
