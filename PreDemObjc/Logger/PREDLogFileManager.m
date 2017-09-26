//
//  PREDLogFileManager.m
//  Pods
//
//  Created by 王思宇 on 05/09/2017.
//
//

#import "PREDLogFileManager.h"
#import "PREDHelper.h"

@implementation PREDLogFileManager

- (NSString *)newLogFileName {
    NSString *logFileName = [super newLogFileName];
    if ([self.delegate respondsToSelector:@selector(logFileManager:willCreatedNewLogFile:)]) {
        [self.delegate logFileManager:self willCreatedNewLogFile:logFileName];
    }
    return logFileName;
}

@end
