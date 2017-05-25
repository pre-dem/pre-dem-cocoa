//
//  PRESNetDiagResult.m
//  Pods
//
//  Created by WangSiyu on 25/05/2017.
//
//

#import "PRESNetDiagResult.h"
#import "PRESUtilities.h"

@implementation PRESNetDiagResult

- (NSDictionary *)toDic {
    return [PRESUtilities getObjectData:self];
}

@end
