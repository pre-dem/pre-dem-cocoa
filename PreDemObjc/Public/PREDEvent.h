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

@property (nonatomic, assign) NSString* name;
@property (nonatomic, assign) NSString* content;
@property (nonatomic, assign) NSString* type;

@end

#endif /* PREDEvent_h */
