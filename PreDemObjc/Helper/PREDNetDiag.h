//
//  PREDNetDiag.h
//  Pods
//
//  Created by WangSiyu on 24/05/2017.
//

#import <Foundation/Foundation.h>
#import "PreDemObjc.h"

@interface PREDNetDiag : NSObject

+ (void)diagnose:(NSString *)host
          appKey:(NSString *)appKey
        complete:(PREDNetDiagCompleteHandler)complete;

@end
