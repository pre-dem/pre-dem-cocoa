//
//  PREDCrashMeta.h
//  Pods
//
//  Created by 王思宇 on 15/09/2017.
//
//

#import <Foundation/Foundation.h>
#import "PREDBaseModel.h"

@interface PREDCrashMeta : PREDBaseModel

@property (nonatomic, strong) NSString *report_uuid;
@property (nonatomic, strong) NSString *crash_log_key;
@property (nonatomic, assign) uint64_t start_time;
@property (nonatomic, assign) uint64_t crash_time;

- (instancetype)initWithData:(NSData *)crashData error:(NSError **)error;

@end
