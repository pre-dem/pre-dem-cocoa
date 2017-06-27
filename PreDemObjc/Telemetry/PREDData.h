#import "PREDBase.h"
@class PREDTelemetryData;

@interface PREDData : PREDBase <NSCoding>

@property (nonatomic, strong) PREDTelemetryData *baseData;

- (instancetype)initWithCoder:(NSCoder *)coder;

- (void)encodeWithCoder:(NSCoder *)coder;


@end
