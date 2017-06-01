// Adapted from 0xced’s post at http://stackoverflow.com/questions/34732814/how-should-i-handle-logs-in-an-objective-c-library/34732815#34732815

#import <Foundation/Foundation.h>
#import "PRESEnums.h"

#define PRESLog(_level, _message) [PRESLogger logMessage:_message level:_level file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]

#define PRESLogError(format, ...)   PRESLog(PRESLogLevelError,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define PRESLogWarning(format, ...) PRESLog(PRESLogLevelWarning, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define PRESLogDebug(format, ...)   PRESLog(PRESLogLevelDebug,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define PRESLogVerbose(format, ...) PRESLog(PRESLogLevelVerbose, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))

@interface PRESLogger : NSObject

+ (PRESLogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(PRESLogLevel)currentLogLevel;
+ (void)setLogHandler:(PRESLogHandler)logHandler;

+ (void)logMessage:(PRESLogMessageProvider)messageProvider level:(PRESLogLevel)loglevel file:(const char *)file function:(const char *)function line:(uint)line;

@end
