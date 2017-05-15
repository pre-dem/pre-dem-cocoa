#import "PRESTelemetryObject.h"

@interface PRESInternal : PRESTelemetryObject <NSCoding>

@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *agentVersion;

@end
