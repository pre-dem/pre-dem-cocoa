//
//  PREDLogFormatter.h
//  Pods
//
//  Created by 王思宇 on 05/09/2017.
//
//

#import <Foundation/Foundation.h>
#import <CocoaLumberjack/CocoaLumberjack.h>

@class PREDLogFormatter;

@protocol PREDLogFormatterDelegate <NSObject>

- (void)logFormatter:(PREDLogFormatter *)logFormatter willFormatMessage:(DDLogMessage *)logMessage;

@end

@interface PREDLogFormatter : NSObject
<
DDLogFormatter
>

@property (nonatomic, weak) id<PREDLogFormatterDelegate> delegate;

@end
