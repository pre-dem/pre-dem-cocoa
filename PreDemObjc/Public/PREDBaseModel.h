//
//  PREDBaseModel.h
//  Pods
//
//  Created by 王思宇 on 15/09/2017.
//
//

#import <Foundation/Foundation.h>

/**
 * 上报数据的基类，包装一些基本信息
 */
@interface PREDBaseModel : NSObject

/**
 * 自定义事件的名称
 */
@property (nonatomic, strong, readonly) NSString* name;

/**
 * 事件的类型，自定义事件恒为 @"custom"
 */
@property (nonatomic, strong, readonly) NSString* type;

/**
 * 事件生成的时间
 */
@property (nonatomic, assign) int64_t time;

/**
 * 宿主 app 的包名，即宿主 app 的 CFBundleIdentifier 属性
 */
@property (nonatomic, strong) NSString *app_bundle_id;

/**
 * 宿主 app 的名称，即宿主 app 的 CFBundleName 属性
 */
@property (nonatomic, strong) NSString *app_name;

/**
 * 宿主 app 的版本，即宿主 app 的 CFBundleShortVersionString 属性
 */
@property (nonatomic, strong) NSString *app_version;

/**
 * 宿主 app 的型号
 */
@property (nonatomic, strong) NSString *device_model;

/**
 * 宿主 app 的平台
 */
@property (nonatomic, strong) NSString *os_platform;

/**
 * 宿主 app 的系统版本号
 */
@property (nonatomic, strong) NSString *os_version;

/**
 * 宿主 app 的构建号
 */
@property (nonatomic, strong) NSString *os_build;

/**
 * sdk 的版本号
 */
@property (nonatomic, strong) NSString *sdk_version;

/**
 * 设备及 app 唯一的识别号
 */
@property (nonatomic, strong) NSString *sdk_id;

/**
 * 用户标签，与 PREDManager 设置的一致
 */
@property (nonatomic, strong) NSString *tag;

/**
 * 设备制造商
 */
@property (nonatomic, strong) NSString *manufacturer;

/**
 * 生成一个事件对象
 *
 * @param name 事件的名称
 * @param type 事件的类型
 */
+ (instancetype)eventWithName:(NSString *)name type:(NSString *)type;

/**
 * 初始化一个事件对象
 *
 * @param name 事件的名称
 * @param type 事件的类型
 */
- (instancetype)initWithName:(NSString *)name type:(NSString *)type;

@end
