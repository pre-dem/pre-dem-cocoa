//
//  PREDHTTPMonitorModel.m
//  PreDemCocoa
//
//  Created by WangSiyu on 15/03/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDHTTPMonitorModel.h"
#import "PREDConstants.h"

@implementation PREDHTTPMonitorModel

- (instancetype)init {
    return [self initWithName:HttpMonitorEventName type:AutoCapturedEventType];
}

- (void)setPath:(NSString *)path {
    _path = path;
    NSArray *pathsComponents = [path componentsSeparatedByString:@"/"];
    [pathsComponents enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        // 第一部分为空，舍去
        if (idx >0 && idx < 5) {
            [self setValue:obj forKey:[NSString stringWithFormat:@"path%lu", (unsigned long)idx]];
        }
    }];

    // 如果层级超过四层，则 path4 携带剩余所有 path 的值
    if (pathsComponents.count > 5) {
        // 1 + path1.length + 1 + path2.length + 1 + path2.length + 1
        _path4 = [path substringFromIndex:(_path1.length + _path2.length + _path3.length + 4)];
    }
}

@end
