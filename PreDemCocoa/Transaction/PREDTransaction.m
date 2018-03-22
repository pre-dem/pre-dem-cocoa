//
//  PREDTransaction.m
//  CocoaLumberjack
//
//  Created by WangSiyu on 21/03/2018.
//

#import "PREDTransaction.h"
#import "PREDConstants.h"

@implementation PREDTransaction

- (instancetype)init {
    return [self initWithName:TransactionEventName type:CustomEventType];
}

@end
