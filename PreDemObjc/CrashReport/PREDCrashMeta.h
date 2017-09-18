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
@property (nonatomic, assign) unsigned long start_time;
@property (nonatomic, assign) unsigned long crash_time;

- (instancetype)initWithData:(NSData *)crashData error:(NSError **)error;

@end
