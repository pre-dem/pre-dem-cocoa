#import "PRESDomain.h"
#import "PRESSessionState.h"

@interface PRESSessionStateData : PRESDomain <NSCoding>

@property (nonatomic, copy, readonly) NSString *envelopeTypeName;
@property (nonatomic, copy, readonly) NSString *dataTypeName;
@property (nonatomic, assign) PRESSessionState state;

@end
