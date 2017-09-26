//
//  PREDLogMeta.m
//  Pods
//
//  Created by 王思宇 on 18/09/2017.
//
//

#import "PREDLogMeta.h"

@implementation PREDLogMeta {
    NSMutableSet *_tags;
}

- (instancetype)init {
    if (self = [super init]) {
        _tags = [NSMutableSet new];
    }
    return self;
}

- (BOOL)addLogTag:(NSString *)tag {
    BOOL exist = [_tags containsObject:tag];
    if (!exist) {
        [_tags addObject:tag];
        _log_tags = [self logTagsString];
    }
    return exist;
}

- (NSString *)logTagsString {
    __block NSString *result;
    [_tags enumerateObjectsUsingBlock:^(NSString* obj, BOOL * stop) {
        if (!result) {
            result = obj;
        } else {
            result = [NSString stringWithFormat:@"%@\t%@", result, obj];
        }
    }];
    return result;
}

@end
