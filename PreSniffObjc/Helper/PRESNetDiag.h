//
//  PRESNetDiag.h
//  Pods
//
//  Created by WangSiyu on 24/05/2017.
//
//

#import <Foundation/Foundation.h>
#import "PreSniffObjc.h"

@interface PRESNetDiag : NSObject

+ (void)diagnose:(NSString *)host
          appKey:(NSString *)appKey
        complete:(PRESNetDiagCompleteHandler)complete;

@end
