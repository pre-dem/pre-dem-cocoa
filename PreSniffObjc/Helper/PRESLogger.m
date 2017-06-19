#import "PRESLogger.h"
#import "PreSniffObjc.h"

@implementation PRESLogger

static PRESLogLevel _currentLogLevel = PRESLogLevelWarning;
static PRESLogHandler currentLogHandler;

static NSString *levelString(PRESLogLevel logLevel) {
    switch (logLevel) {
        case PRESLogLevelNone:
            return @"None";
            break;
        case PRESLogLevelError:
            return @"Error";
        case PRESLogLevelWarning:
            return @"Warning";
        case PRESLogLevelDebug:
            return @"Debug";
        case PRESLogLevelVerbose:
            return @"Verbose";
        default:
            return @"";
            break;
    }
}

PRESLogHandler defaultLogHandler = ^(PRESLogMessageProvider messageProvider, PRESLogLevel logLevel, const char *file, const char *function, uint line) {
    if (messageProvider) {
        if (_currentLogLevel < logLevel) {
            return;
        }
        NSLog((@"[PreSniffObjc]%@: %s/%d %@"), levelString(logLevel), function, line, messageProvider());
    }
};


+ (void)initialize {
    currentLogHandler = defaultLogHandler;
}

+ (PRESLogLevel)currentLogLevel {
    return _currentLogLevel;
}

+ (void)setCurrentLogLevel:(PRESLogLevel)currentLogLevel {
    _currentLogLevel = currentLogLevel;
}

+ (void)setLogHandler:(PRESLogHandler)logHandler {
    currentLogHandler = logHandler;
}

+ (void)logMessage:(PRESLogMessageProvider)messageProvider level:(PRESLogLevel)loglevel file:(const char *)file function:(const char *)function line:(uint)line {
    if (currentLogHandler) {
        currentLogHandler(messageProvider, loglevel, file, function, line);
    }
}

@end
