#import "PRESBase.h"
@class PRESTelemetryData;

@interface PRESData : PRESBase <NSCoding>

@property (nonatomic, strong) PRESTelemetryData *baseData;

- (instancetype)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;


@end
