#import "PREDDomain.h"
#import "PREDSessionState.h"

@interface PREDSessionStateData : PREDDomain <NSCoding>

@property (nonatomic, copy, readonly) NSString *envelopeTypeName;
@property (nonatomic, copy, readonly) NSString *dataTypeName;
@property (nonatomic, assign) PREDSessionState state;

@end
