//
//  PREDLogMeta.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDLogMeta.h"

@implementation PREDLogMeta

- (instancetype)initWithLogKey:(NSString *)logKey
                     startTime:(uint64_t)startTime
                       endTime:(uint64_t)endTime
                       logTags:(NSString *)logTags
                    errorCount:(unsigned long)errorCount{
    if (self = [super init]) {
        _log_key = logKey;
        _start_time = startTime;
        _end_time = endTime;
        _log_tags = logTags;
        _error_count = errorCount;
    }
    return self;
}

@end
