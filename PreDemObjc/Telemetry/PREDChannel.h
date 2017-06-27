#import <Foundation/Foundation.h>

@class PREDConfiguration;
@class PREDTelemetryData;
@class PREDTelemetryContext;
@class PREDPersistence;

#import "PREDNullability.h"
NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT char *PREDSafeJsonEventsString;

/**
 *  Items get queued before they are persisted and sent out as a batch. This class managed the queue, and forwards the batch
 *  to the persistence layer once the max batch count has been reached.
 */
@interface PREDChannel : NSObject


/**
 *  Initializes a new PREDChannel instance.
 *
 *  @param telemetryContext the context used to add context values to the metrics payload
 *  @param persistence the persistence used to save metrics after the queue gets flushed
 *
 *  @return the telemetry context
 */
- (instancetype)initWithTelemetryContext:(PREDTelemetryContext *)telemetryContext persistence:(PREDPersistence *) persistence;

/**
 *  Reset PREDSafeJsonEventsString so we can start appending JSON dictionaries.
 *
 *  @param item The telemetry object, which should be processed
 */
- (void)enqueueTelemetryItem:(PREDTelemetryData *)item;

@end

NS_ASSUME_NONNULL_END
