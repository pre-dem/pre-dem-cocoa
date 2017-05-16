#import "PRESTelemetryObject.h"
#import "PRESTelemetryData.h"

@interface PRESBase : PRESTelemetryData <NSCoding>

@property (nonatomic, copy) NSString *baseType;

- (instancetype)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;


@end
