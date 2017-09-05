//
//  PREDLogFileManager.h
//  Pods
//
//  Created by 王思宇 on 05/09/2017.
//
//

#import <CocoaLumberjack/CocoaLumberjack.h>

@class PREDLogFileManager;

@protocol PREDLogFileManagerDelegate <NSObject>

@required
- (void)logFileManager:(PREDLogFileManager *)logFileManager didArchivedLogFile:(NSString *)logFilePath;

@end

@interface PREDLogFileManager : DDLogFileManagerDefault

@property (nonatomic, weak) id<PREDLogFileManagerDelegate> delegate;

@end
