//
//  PREDEventPrivate.h
//  PreDemObjc
//
//  Created by Troy on 2017/9/27.
//

#ifndef PREDEventPrivate_h
#define PREDEventPrivate_h
#import "PREDEvent.h"

@interface PREDEvent ()

- (instancetype)initWithName:(NSString *)name content:(NSString *)content;
- (instancetype)initWithName:(NSString *)name content:(NSString *)content type:(NSString *)type;

@end

#endif /* PREDEventPrivate_h */
