//
//  PREDCrashManager.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDPersistence.h"

@interface PREDCrashManager : NSObject

@property(nonatomic, assign) BOOL started;

- (instancetype)initWithPersistence:(PREDPersistence *)persistence;

@end
