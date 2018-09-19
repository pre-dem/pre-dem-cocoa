//
//  PREDManager.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import "PREDCustomEvent.h"
#import "PREDDefines.h"
#import "PREDTransaction.h"
#import <Foundation/Foundation.h>

/**
 * PREDManager 是 sdk 的核心类，提供 sdk 的主要对外接口
 */
@interface PREDManager : NSObject

#pragma mark - Public Methods

/**
 * 启动 PREDManager，如果您使用的是我们的公有云产品，相关参数请通过
 * https://predem.qiniu.com 获取
 *
 * @param appKey 用于唯一标识单个 app
 * @param serviceDomain 数据上传的服务器域名
 */
+ (void)startWithAppKey:(NSString *_Nonnull)appKey
          serviceDomain:(NSString *_Nonnull)serviceDomain;

/**
 *  开始一个 transaction
 *
 *  @param transactionName 该 transaction 的名字
 *  @return 该 transaction 对应的 实例
 */
+ (PREDTransaction *_Nonnull)transactionStart:
    (NSString *_Nonnull)transactionName;

/**
 *  上报自定义事件
 *
 *  @param event 需要上报的自定义事件对象
 */
+ (void)trackCustomEvent:(PREDCustomEvent *_Nonnull)event;

/**
 * 返回 sdk 的版本号
 */
+ (NSString *_Nonnull)version;

/**
 * 返回 sdk 的构建号
 */
+ (NSString *_Nonnull)build;

#pragma mark - Public Properties

/**
 * 用户标签，用于标识唯一用户，例如您可以传入用户ID，我们将透传该字段，以便您可以在后台通过用户标签查找对应用户的数据
 */
@property(class, nonnull, nonatomic, strong) NSString *tag;

/**
 * 配置上报频率，单位秒，最小30秒，最大1800秒
 */
@property(class) NSUInteger updateInterval;

/**
 * 返回 该终端是否是重点关注对象，终端可以根据这个字段调整队列参数
 */
+ (BOOL)isVip;

@end
