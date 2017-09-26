//
//  PREDLogMeta.h
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDBaseModel.h"

@interface PREDLogMeta : PREDBaseModel

@property (nonatomic, strong) NSString *log_key;
@property (nonatomic, assign) uint64_t start_time;
@property (nonatomic, assign) uint64_t end_time;
@property (nonatomic, strong) NSString *log_tags;
@property (nonatomic, assign) unsigned long error_count;

- (BOOL)addLogTag:(NSString *)tag;

@end
