//
//  PREDBreadcrumbTracker.h
//  PRED
//
//  Created by Daniel Griesser on 31/05/2017.
//  Copyright © 2017 PRED. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDPersistence.h"

@interface PREDBreadcrumbTracker : NSObject

- (instancetype)initWithPersistence:(PREDPersistence *)persistence;

- (void)start;

@end
