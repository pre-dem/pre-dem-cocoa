// Adapted from 0xced’s post at http://stackoverflow.com/questions/34732814/how-should-i-handle-logs-in-an-objective-c-library/34732815#34732815

#import <Foundation/Foundation.h>
#import "PRESEnums.h"

#define PRESHockeyLog(_level, _message) [PRESLogger logMessage:_message level:_level file:__FILE__ function:__PRETTY_FUNCTION__ line:__LINE__]

#define PRESHockeyLogError(format, ...)   PRESHockeyLog(PRESLogLevelError,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define PRESHockeyLogWarning(format, ...) PRESHockeyLog(PRESLogLevelWarning, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define PRESHockeyLogDebug(format, ...)   PRESHockeyLog(PRESLogLevelDebug,   (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))
#define PRESHockeyLogVerbose(format, ...) PRESHockeyLog(PRESLogLevelVerbose, (^{ return [NSString stringWithFormat:(format), ##__VA_ARGS__]; }))

@interface PRESLogger : NSObject

+ (PRESLogLevel)currentLogLevel;
+ (void)setCurrentLogLevel:(PRESLogLevel)currentLogLevel;
+ (void)setLogHandler:(PRESLogHandler)logHandler;

+ (void)logMessage:(PRESLogMessageProvider)messageProvider level:(PRESLogLevel)loglevel file:(const char *)file function:(const char *)function line:(uint)line;

@end
