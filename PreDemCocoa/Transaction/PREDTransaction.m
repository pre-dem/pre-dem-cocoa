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
    if (self = [self initWithName:TransactionEventName type:AutoCapturedEventType]) {
    }
    return self;
}

@end
