//
//  PREDNetDiag.h
//  PreDemCocoa
//
//  Created by WangSiyu on 24/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDPersistence.h"
#import "PreDemCocoa.h"
#import <Foundation/Foundation.h>

@interface PREDNetDiag : NSObject

+ (void)diagnose:(NSString *)host
     persistence:(PREDPersistence *)persistence
        complete:(PREDNetDiagCompleteHandler)complete;

@end
