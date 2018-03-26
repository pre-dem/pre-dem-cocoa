//
//  PREDTransaction.m
//  CocoaLumberjack
//
//  Created by WangSiyu on 21/03/2018.
//

#import "PREDTransactionPrivate.h"
#import "PREDConstants.h"
#import "PREDPersistence.h"

@implementation PREDTransaction {
    PREDPersistence *_persistence;
}

+ (PREDTransaction *)transactionWithPersistence:(PREDPersistence *)persistence {
    PREDTransaction *object = [[PREDTransaction alloc] initWithName:TransactionEventName type:CustomEventType];
    object->_persistence = persistence;
    return object;
}

- (void)complete {
    uint64_t endTime = (uint64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
    self.end_time = endTime;
    self.transaction_type = PREDTransactionTypeCompleted;
    [_persistence persistTransaction:self];
}

- (void)cancelWithReason:(NSString *)reason {
    uint64_t endTime = (uint64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
    self.end_time = endTime;
    self.transaction_type = PREDTransactionTypeCancelled;
    self.reason = reason;
    [_persistence persistTransaction:self];
}

- (void)failWithReason:(NSString *)reason {
    uint64_t endTime = (uint64_t) ([[NSDate date] timeIntervalSince1970] * 1000);
    self.end_time = endTime;
    self.transaction_type = PREDTransactionTypeFailed;
    self.reason = reason;
    [_persistence persistTransaction:self];
}

@end
