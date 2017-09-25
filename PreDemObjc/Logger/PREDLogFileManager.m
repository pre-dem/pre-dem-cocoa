//
//  PREDLogFileManager.m
//  Pods
//
//  Created by 王思宇 on 05/09/2017.
//
//

#import "PREDLogFileManager.h"

@implementation PREDLogFileManager

+ (instancetype)sharedManager {
    static PREDLogFileManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[PREDLogFileManager alloc] init];
    });
    return manager;
}

- (NSString *)createNewLogFile {
    NSString *logFilePath = [super createNewLogFile];
    [self.delegate logFileManager:self willCreatedNewLogFile:logFilePath];
    return logFilePath;
}

@end
