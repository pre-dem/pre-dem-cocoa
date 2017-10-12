//
//  PREDEvent.h
//  PreDemObjc
//
//  Created by Troy on 2017/9/26.
//

#ifndef PREDEvent_h
#define PREDEvent_h
#import <Foundation/Foundation.h>
#import "PREDBaseModel.h"

@interface PREDEvent: PREDBaseModel

@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSString* content;
@property (nonatomic, strong, readonly) NSString* type;

+ (instancetype)eventWithName:(NSString *)name contentDic:(NSDictionary *)contentDic;
+ (instancetype)eventWithName:(NSString *)name type:(NSString *)type contentDic:(NSDictionary *)contentDic;

@end

#endif /* PREDEvent_h */
