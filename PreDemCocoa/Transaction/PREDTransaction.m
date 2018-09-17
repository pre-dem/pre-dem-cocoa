//
//  PREDTransaction.m
//  CocoaLumberjack
//
//  Created by WangSiyu on 21/03/2018.
//

#import "PREDTransactionPrivate.h"
#import "PREDConstants.h"
#import "PREDSender.h"

#import "PREDManager.h"

@implementation PREDTransaction {
  PREDSender *_sender;
}

+ (PREDTransaction *)transactionWithSender:(PREDSender *)sender {
  PREDTransaction *object =
      [[PREDTransaction alloc] initWithName:TransactionEventName
                                       type:CustomEventType];
  object->_sender = sender;
  return object;
}

- (void)complete {
  uint64_t endTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
  self.end_time = endTime;
  self.transaction_type = PREDTransactionTypeCompleted;
  [_sender persistTransaction:self];
}

- (void)cancelWithReason:(NSString *)reason {
  uint64_t endTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
  self.end_time = endTime;
  self.transaction_type = PREDTransactionTypeCancelled;
  self.reason = reason;
  [_sender persistTransaction:self];
}

- (void)failWithReason:(NSString *)reason {
  uint64_t endTime = (uint64_t)([[NSDate date] timeIntervalSince1970] * 1000);
  self.end_time = endTime;
  self.transaction_type = PREDTransactionTypeFailed;
  self.reason = reason;
  [_sender persistTransaction:self];
}

@end

@implementation PREDTransactionQueue

- (void)setSizeThreshhold:(NSUInteger)size {
}

- (NSUInteger)sizeThreshhold {
  return 10;
}

- (void)setSendInterval:(NSUInteger)interval {
}

- (NSUInteger)sendInterval {
  return 30;
}

- (PREDTransaction *_Nonnull)transactionStart:
    (NSString *_Nonnull)transactionName {
  return [PREDManager transactionStart:transactionName];
}

@end
