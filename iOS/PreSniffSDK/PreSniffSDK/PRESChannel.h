#import <Foundation/Foundation.h>
#import "PreSniffSDKFeatureConfig.h"

#if HOCKEYSDK_FEATURE_METRICS

@class PRESConfiguration;
@class PRESTelemetryData;
@class PRESTelemetryContext;
@class PRESPersistence;

#import "PreSniffSDKNullability.h"
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT char *PRESSafeJsonEventsString;

/**
 *  Items get queued before they are persisted and sent out as a batch. This class managed the queue, and forwards the batch
 *  to the persistence layer once the max batch count has been reached.
 */
@interface PRESChannel : NSObject


/**
 *  Initializes a new PRESChannel instance.
 *
 *  @param telemetryContext the context used to add context values to the metrics payload
 *  @param persistence the persistence used to save metrics after the queue gets flushed
 *
 *  @return the telemetry context
 */
- (instancetype)initWithTelemetryContext:(PRESTelemetryContext *)telemetryContext persistence:(PRESPersistence *) persistence;

/**
 *  Reset PRESSafeJsonEventsString so we can start appending JSON dictionaries.
 *
 *  @param item The telemetry object, which should be processed
 */
- (void)enqueueTelemetryItem:(PRESTelemetryData *)item;

@end

NS_ASSUME_NONNULL_END

#endif /* HOCKEYSDK_FEATURE_METRICS */
