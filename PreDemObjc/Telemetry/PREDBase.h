#import "PREDTelemetryObject.h"
#import "PREDTelemetryData.h"

@interface PREDBase : PREDTelemetryData <NSCoding>

@property (nonatomic, copy) NSString *baseType;

- (instancetype)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;


@end
