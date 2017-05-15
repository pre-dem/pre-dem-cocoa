#import <Foundation/Foundation.h>
#import "PreSniffObjcFeatureConfig.h"

#if HOCKEYSDK_FEATURE_METRICS

#import "PreSniffSDKNullability.h"
NS_ASSUME_NONNULL_BEGIN

@interface PRESCategoryContainer : NSObject

+ (void)activateCategory;

@end

NS_ASSUME_NONNULL_END

#endif /* HOCKEYSDK_FEATURE_METRICS */
