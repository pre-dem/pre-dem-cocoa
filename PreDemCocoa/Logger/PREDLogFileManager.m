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

- (void)didArchiveLogFile:(NSString *)logFilePath {
    if ([self.delegate respondsToSelector:@selector(logFileManager:willArchiveLogFile:)]) {
        NSString *fileName = [[logFilePath componentsSeparatedByString:@"/"] lastObject];
        [self.delegate logFileManager:self willArchiveLogFile:fileName];
    }
}

- (void)didRollAndArchiveLogFile:(NSString *)logFilePath {
    if ([self.delegate respondsToSelector:@selector(logFileManager:willArchiveLogFile:)]) {
        NSString *fileName = [[logFilePath componentsSeparatedByString:@"/"] lastObject];
        [self.delegate logFileManager:self willArchiveLogFile:fileName];
    }
}

- (NSString *)newLogFileName {
    NSString *logFileName = [super newLogFileName];
    if ([self.delegate respondsToSelector:@selector(logFileManager:willCreatedNewLogFile:)]) {
        [self.delegate logFileManager:self willCreatedNewLogFile:logFileName];
    }
    return logFileName;
}

@end
