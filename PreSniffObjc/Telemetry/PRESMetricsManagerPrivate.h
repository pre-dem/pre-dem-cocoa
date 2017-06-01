#import "PRESMetricsManager.h"
#import "PRESSessionState.h"

@class PRESChannel;
@class PRESTelemetryContext;
@class PRESSession;
@class PRESPersistence;
@class PRESSender;

#import "PRESNullability.h"
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *const kPRESApplicationWasLaunched;

@interface PRESMetricsManager()

/**
 *  Create a new PRESMetricsManager instance by passing the channel, the telemetry context, and persistence instance to use
 for processing metrics. This method can be used for dependency injection.
 */
- (instancetype)initWithChannel:(PRESChannel *)channel
               telemetryContext:(PRESTelemetryContext *)telemetryContext
                    persistence:(PRESPersistence *)persistence
                   userDefaults:(NSUserDefaults *)userDefaults;

/**
 *  The user defaults object used to store meta data.
 */
@property (nonatomic, strong, readonly) NSUserDefaults *userDefaults;

/**
 *  A channel for collecting new events before storing and sending them.
 */
@property (nonatomic, strong, readonly) PRESPersistence *persistence;

/**
 *  A channel for collecting new events before storing and sending them.
 */
@property (nonatomic, strong, readonly) PRESChannel *channel;

/**
 *  A telemetry context which is used to add meta info to events, before they're sent out.
 */
@property (nonatomic, strong, readonly) PRESTelemetryContext *telemetryContext;

/**
 *  A concurrent queue which creates and processes telemetry items.
 */
@property (nonatomic, strong, readonly) dispatch_queue_t metricsEventQueue;

/**
 *  Sender instance to send out telemetry data.
 */
@property (nonatomic, strong) PRESSender *sender;

///-----------------------------------------------------------------------------
/// @name Session Management
///-----------------------------------------------------------------------------

/**
 *  The Interval an app has to be in the background until the current session gets renewed.
 */
@property (nonatomic, assign) NSUInteger appBackgroundTimeBeforeSessionExpires;

/**
 *  Registers manager for several notifications, which influence the session state.
 */
- (void)registerObservers;

/**
 *  Unregisters manager for several notifications, which influence the session state.
 */
- (void)unregisterObservers;

/**
 *  Stores the current date before app is sent to background.
 *
 *  @see appBackgroundTimeBeforeSessionExpires
 *  @see startNewSessionIfNeeded
 */
- (void)updateDidEnterBackgroundTime;

/**
 *  Determines whether the current session needs to be renewed or not.
 *
 *  @see appBackgroundTimeBeforeSessionExpires
 *  @see updateDidEnterBackgroundTime
 */
- (void)startNewSessionIfNeeded;

/**
 *  Creates a new session, updates the session context and sends it to the channel.
 *
 *  @param sessionId the id for the new session
 */
- (void)startNewSessionWithId:(NSString *)sessionId;

/**
 *  Creates a new session and stores it to NSUserDefaults.
 *
 *  @param sessionId the id for the new session
 *  @return the newly created session
 */
- (PRESSession *)createNewSessionWithId:(NSString *)sessionId;

///-----------------------------------------------------------------------------
/// @name Track telemetry data
///-----------------------------------------------------------------------------

/**
 *  Creates and enqueues a session event for the given state.
 *
 *  @param state value that determines whether the session started or ended
 */
- (void)trackSessionWithState:(PRESSessionState)state;

@end

NS_ASSUME_NONNULL_END
