#import "PREDTelemetryObject.h"

@interface PREDSession : PREDTelemetryObject <NSCoding>

@property (nonatomic, copy) NSString *sessionId;
@property (nonatomic, copy) NSString *isFirst;
@property (nonatomic, copy) NSString *isNew;

@end
