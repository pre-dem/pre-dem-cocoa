//
//  PREDManager.h
//  PreDemCocoa
//
//  Created by WangSiyu on 21/02/2017.
//  Copyright © 2017 pre-engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PREDDefines.h"
#import "PREDCustomEvent.h"

/**
 * PREDManager 是 sdk 的核心类，提供 sdk 的主要对外接口
 */
@interface PREDManager: NSObject

#pragma mark - Public Methods

/**
 * 启动 PREDManager，如果您使用的是我们的公有云产品，相关参数请通过 https://predem.qiniu.com 获取
 *
 * @param appKey 用于唯一标识单个 app
 * @param serviceDomain 数据上传的服务器域名
 */
+ (void)startWithAppKey:(NSString *_Nonnull)appKey
          serviceDomain:(NSString *_Nonnull)serviceDomain
               complete:(PREDStartCompleteHandler _Nullable)complete;

/**
 *  获取当前网络环境下对指定服务器的网络诊断信息并上报
 *
 *  @param host 需要诊断的服务器地址
 *  @param complete 诊断结果返回
 */
+ (void)diagnose:(NSString *_Nonnull)host
        complete:(PREDNetDiagCompleteHandler _Nullable)complete;

/**
 *  上报自定义事件
 *
 *  @param event 需要上报的自定义事件对象
 */
+ (void)trackCustomEvent:(PREDCustomEvent *_Nonnull)event;

/**
 * 返回 SDK 是否处于已启动的状态
 */
+ (BOOL)started;

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
@property (class, nonnull, nonatomic, strong) NSString *tag;

@end
