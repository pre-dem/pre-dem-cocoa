//
//  PREDURLProtocol.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDPersistence.h"

@interface PREDURLProtocol : NSURLProtocol

@property(class, nonatomic) BOOL started;

+ (void)setPersistence:(PREDPersistence *)persistence;

@end
