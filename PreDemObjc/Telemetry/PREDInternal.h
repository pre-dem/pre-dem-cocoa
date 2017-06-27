#import "PREDTelemetryObject.h"

@interface PREDInternal : PREDTelemetryObject <NSCoding>

@property (nonatomic, copy) NSString *sdkVersion;
@property (nonatomic, copy) NSString *agentVersion;

@end
