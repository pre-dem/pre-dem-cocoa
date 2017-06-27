#import "PREDTelemetryObject.h"
@class PREDBase;

@interface PREDEnvelope : PREDTelemetryObject <NSCoding>

@property (nonatomic, copy) NSNumber *version;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *time;
@property (nonatomic, copy) NSNumber *sampleRate;
@property (nonatomic, copy) NSString *seq;
@property (nonatomic, copy) NSString *iKey;
@property (nonatomic, copy) NSNumber *flags;
@property (nonatomic, copy) NSString *deviceId;
@property (nonatomic, copy) NSString *os;
@property (nonatomic, copy) NSString *osVer;
@property (nonatomic, copy) NSString *appId;
@property (nonatomic, copy) NSString *appVer;
@property (nonatomic, copy) NSString *userId;
@property (nonatomic, strong) NSDictionary *tags;
@property (nonatomic, strong) PREDBase *data;


@end
