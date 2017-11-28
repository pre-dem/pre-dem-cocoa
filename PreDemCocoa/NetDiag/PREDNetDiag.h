//
//  PREDNetDiag.h
//  PreDemCocoa
//
//  Created by WangSiyu on 24/05/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PreDemCocoa.h"
#import "PREDPersistence.h"

@interface PREDNetDiag : NSObject

+ (void)diagnose:(NSString *)host
     persistence:(PREDPersistence *)persistence
        complete:(PREDNetDiagCompleteHandler)complete;

@end
