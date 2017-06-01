#import "PRESTelemetryObject.h"

#import "PRESNullability.h"
NS_ASSUME_NONNULL_BEGIN

///Data contract class for type PRESTelemetryData.
@interface PRESTelemetryData : PRESTelemetryObject <NSCoding>

@property (nonatomic, readonly, copy) NSString *envelopeTypeName;
@property (nonatomic, readonly, copy) NSString *dataTypeName;

@property (nonatomic, copy) NSNumber *version;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSDictionary *properties;

@end

NS_ASSUME_NONNULL_END
