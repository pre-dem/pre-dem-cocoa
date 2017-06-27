#import <Foundation/Foundation.h>
#import "PREDApplication.h"
#import "PREDDevice.h"
#import "PREDInternal.h"
#import "PREDUser.h"
#import "PREDSession.h"

@class PREDPersistence;

#import "PREDNullability.h"
NS_ASSUME_NONNULL_BEGIN

/**
 *  Context object which contains information about the device, user, session etc.
 */
@interface PREDTelemetryContext : NSObject

///-----------------------------------------------------------------------------
/// @name Initialisation
///-----------------------------------------------------------------------------

/**
 *  The persistence instance used to save/load metadata.
 */
@property(nonatomic, strong) PREDPersistence *persistence;

/**
 *  The instrumentation key of the app.
 */
@property(nonatomic, copy) NSString *appIdentifier;

/**
 *  A queue which makes array operations thread safe.
 */
@property (nonatomic, strong) dispatch_queue_t operationsQueue;

/**
 *  The application context.
 */
@property(nonatomic, strong, readonly) PREDApplication *application;

/**
 *  The device context.
 */
@property (nonatomic, strong, readonly)PREDDevice *device;

/**
 *  The session context.
 */
@property (nonatomic, strong, readonly)PREDSession *session;

/**
 *  The user context.
 */
@property (nonatomic, strong, readonly)PREDUser *user;

/**
 *  The internal context.
 */
@property (nonatomic, strong, readonly)PREDInternal *internal;

/**
 *  Initializes a telemetry context.
 *
 *  @param appIdentifier the appIdentifier of the app
 *  @param persistence the persistence used to save and load metadata
 *
 *  @return the telemetry context
 */
- (instancetype)initWithAppIdentifier:(NSString *)appIdentifier persistence:(PREDPersistence *)persistence;

///-----------------------------------------------------------------------------
/// @name Helper
///-----------------------------------------------------------------------------

/**
 *  A dictionary which holds static tag fields for the purpose of caching
 */
@property (nonatomic, strong) NSDictionary *tags;

/**
 *  Returns context objects as dictionary.
 *
 *  @return a dictionary containing all context fields
 */
- (NSDictionary *)contextDictionary;

///-----------------------------------------------------------------------------
/// @name Getter/Setter
///-----------------------------------------------------------------------------

- (void)setSessionId:(NSString *)sessionId;

- (void)setIsFirstSession:(NSString *)isFirstSession;

- (void)setIsNewSession:(NSString *)isNewSession;

@end

NS_ASSUME_NONNULL_END
