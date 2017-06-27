#import "PREDDomain.h"

@interface PREDEventData : PREDDomain <NSCoding>

@property (nonatomic, copy, readonly) NSString *envelopeTypeName;
@property (nonatomic, copy, readonly) NSString *dataTypeName;
@property (nonatomic, strong) NSDictionary *measurements;

@end
