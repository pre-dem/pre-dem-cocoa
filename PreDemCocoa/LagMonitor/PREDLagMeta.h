//
//  PREDLagMeta.h
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import <Foundation/Foundation.h>
#import <CrashReporter/CrashReporter.h>
#import "PREDBaseModel.h"

@interface PREDLagMeta : PREDBaseModel

@property (nonatomic, strong) NSString *report_uuid;
@property (nonatomic, strong) NSString *lag_log_key;
@property (nonatomic, assign) uint64_t start_time;
@property (nonatomic, assign) uint64_t lag_time;

- (instancetype)initWithReport:(PREDPLCrashReport *)report;


@end
