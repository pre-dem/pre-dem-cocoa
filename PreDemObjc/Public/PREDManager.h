#import <Foundation/Foundation.h>
#import "PREDNullability.h"
#import "PREDEnums.h"

@protocol PREDManagerDelegate;

@class PREDBaseManager;
@class PREDCrashManager;
@class PREDMetricsManager;

NS_ASSUME_NONNULL_BEGIN

@interface PREDManager: NSObject

#pragma mark - Public Methods

///-----------------------------------------------------------------------------
/// @name Initialization
///-----------------------------------------------------------------------------


/**
 Initialize the manager with a PreDem app identifier.
 
 @param appKey The app key that should be used.
 @param serviceDomain The service domain that data will be reported to or requested from.
 */
+ (void)startWithAppKey:(nonnull NSString *)appKey
          serviceDomain:(nonnull NSString *)serviceDomain;

/**
 *  diagnose current network environment
 *
 *  @param host     the end point you want this diagnose action perform with
 *  @param complete diagnose result can be retrieved from the block
 */
+ (void)diagnose:(nonnull NSString *)host
        complete:(nonnull PREDNetDiagCompleteHandler)complete;

+ (void)trackEventWithName:(nonnull NSString *)eventName
                     event:(nonnull NSDictionary*)event;


///-----------------------------------------------------------------------------
/// @name SDK meta data
///-----------------------------------------------------------------------------

/**
 Returns the SDK Version (CFBundleShortVersionString).
 */
+ (NSString *)version;

/**
 Returns the SDK Build (CFBundleVersion) as a string.
 */
+ (NSString *)build;

#pragma mark - Public Properties

///-----------------------------------------------------------------------------
/// @name Debug Logging
///-----------------------------------------------------------------------------

/**
 This property is used indicate the amount of verboseness and severity for which
 you want to see log messages in the console.
 */
@property (class, nonatomic, assign) PREDLogLevel logLevel;

@end

NS_ASSUME_NONNULL_END
