//
//  PRESEnums.h
//  PreSniffObjc
//
//  Created by Lukas Spieß on 08/10/15.
//
//

#ifndef PreSniffObjc_Enums_h
#define PreSniffObjc_Enums_h

@class PRESNetDiagResult;

/**
 *  PreSniffObjc Log Levels
 */
typedef NS_ENUM(NSUInteger, PRESLogLevel) {
    /**
     *  Logging is disabled
     */
    PRESLogLevelNone = 0,
    /**
     *  Only errors will be logged
     */
    PRESLogLevelError = 1,
    /**
     *  Errors and warnings will be logged
     */
    PRESLogLevelWarning = 2,
    /**
     *  Debug information will be logged
     */
    PRESLogLevelDebug = 3,
    /**
     *  Logging will be very chatty
     */
    PRESLogLevelVerbose = 4
};

/**
 *  PreSniffObjc App environment
 */
typedef NS_ENUM(NSInteger, PRESEnvironment) {
    /**
     *  App has been downloaded from the AppStore
     */
    PRESEnvironmentAppStore = 0,
    /**
     *  App has been downloaded from TestFlight
     */
    PRESEnvironmentTestFlight = 1,
    /**
     *  App has been installed by some other mechanism.
     *  This could be Ad-Hoc, Enterprise, etc.
     */
    PRESEnvironmentOther = 99
};

/**
 *  PreSniffObjc Crash Reporter error domain
 */
typedef NS_ENUM (NSInteger, PRESCrashErrorReason) {
    /**
     *  Unknown error
     */
    PRESCrashErrorUnknown,
    /**
     *  API Server rejected app version
     */
    PRESCrashAPIAppVersionRejected,
    /**
     *  API Server returned empty response
     */
    PRESCrashAPIReceivedEmptyResponse,
    /**
     *  Connection error with status code
     */
    PRESCrashAPIErrorWithStatusCode
};

typedef void (^PRESNetDiagCompleteHandler)(PRESNetDiagResult* result);

typedef NSString *(^PRESLogMessageProvider)(void);

typedef void (^PRESLogHandler)(PRESLogMessageProvider messageProvider, PRESLogLevel logLevel, const char *file, const char *function, uint line);

#endif /* PreSniffObjc_Enums_h */
