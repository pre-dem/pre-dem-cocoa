//
//  PreSniffSDKEnums.h
//  HockeySDK
//
//  Created by Lukas Spieß on 08/10/15.
//
//

#ifndef HockeySDK_HockeyEnums_h
#define HockeySDK_HockeyEnums_h

/**
 *  HockeySDK Log Levels
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

typedef NSString *(^PRESLogMessageProvider)(void);
typedef void (^PRESLogHandler)(PRESLogMessageProvider messageProvider, PRESLogLevel logLevel, const char *file, const char *function, uint line);

/**
 *  HockeySDK App environment
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
 *  HockeySDK Crash Reporter error domain
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

/**
 *  HockeySDK Update error domain
 */
typedef NS_ENUM (NSInteger, PRESUpdateErrorReason) {
    /**
     *  Unknown error
     */
    PRESUpdateErrorUnknown,
    /**
     *  API Server returned invalid status
     */
    PRESUpdateAPIServerReturnedInvalidStatus,
    /**
     *  API Server returned invalid data
     */
    PRESUpdateAPIServerReturnedInvalidData,
    /**
     *  API Server returned empty response
     */
    PRESUpdateAPIServerReturnedEmptyResponse,
    /**
     *  Authorization secret missing
     */
    PRESUpdateAPIClientAuthorizationMissingSecret,
    /**
     *  No internet connection
     */
    PRESUpdateAPIClientCannotCreateConnection
};

/**
 *  HockeySDK Feedback error domain
 */
typedef NS_ENUM(NSInteger, PRESFeedbackErrorReason) {
    /**
     *  Unknown error
     */
    PRESFeedbackErrorUnknown,
    /**
     *  API Server returned invalid status
     */
    PRESFeedbackAPIServerReturnedInvalidStatus,
    /**
     *  API Server returned invalid data
     */
    PRESFeedbackAPIServerReturnedInvalidData,
    /**
     *  API Server returned empty response
     */
    PRESFeedbackAPIServerReturnedEmptyResponse,
    /**
     *  Authorization secret missing
     */
    PRESFeedbackAPIClientAuthorizationMissingSecret,
    /**
     *  No internet connection
     */
    PRESFeedbackAPIClientCannotCreateConnection
};

/**
 *  HockeySDK Authenticator error domain
 */
typedef NS_ENUM(NSInteger, PRESAuthenticatorReason) {
    /**
     *  Unknown error
     */
    PRESAuthenticatorErrorUnknown,
    /**
     *  Network error
     */
    PRESAuthenticatorNetworkError,
    
    /**
     *  API Server returned invalid response
     */
    PRESAuthenticatorAPIServerReturnedInvalidResponse,
    /**
     *  Not Authorized
     */
    PRESAuthenticatorNotAuthorized,
    /**
     *  Unknown Application ID (configuration error)
     */
    PRESAuthenticatorUnknownApplicationID,
    /**
     *  Authorization secret missing
     */
    PRESAuthenticatorAuthorizationSecretMissing,
    /**
     *  Not yet identified
     */
    PRESAuthenticatorNotIdentified,
};

/**
 *  HockeySDK global error domain
 */
typedef NS_ENUM(NSInteger, PRESHockeyErrorReason) {
    /**
     *  Unknown error
     */
    PRESHockeyErrorUnknown
};

#endif /* HockeySDK_HockeyEnums_h */
