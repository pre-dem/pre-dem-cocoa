//
//  PREDTransaction.h
//  CocoaLumberjack
//
//  Created by WangSiyu on 21/03/2018.
//

#import "PREDBaseModel.h"

@interface PREDTransaction : PREDBaseModel

/**
 * transaction 正常结束并上报数据
 *
 */
- (void)complete;

/**
 *  transaction 取消并上报数据
 *
 *  @param reason transaction 被取消的原因
 */
- (void)cancelWithReason:(NSString *_Nullable)reason;

/**
 *  transaction 失败并上报数据
 *
 *  @param reason transaction 被取消的原因
 */
- (void)failWithReason:(NSString *_Nullable)reason;

@end

@interface PREDTransactionQueue : NSObject

@property NSUInteger sizeThreshhold;
@property NSUInteger sendInterval;

- (PREDTransaction *_Nonnull)transactionStart:
    (NSString *_Nonnull)transactionName;

@end
