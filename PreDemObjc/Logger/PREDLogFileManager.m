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

- (void)didArchiveLogFile:(NSString *)logFilePath {
    if ([self.delegate respondsToSelector:@selector(logFileManager:didArchivedLogFile:)]){
        [self.delegate logFileManager:self didArchivedLogFile:logFilePath];
    }
}

- (void)didRollAndArchiveLogFile:(NSString *)logFilePath {
    if ([self.delegate respondsToSelector:@selector(logFileManager:didArchivedLogFile:)]){
        [self.delegate logFileManager:self didArchivedLogFile:logFilePath];
    }
}

@end
