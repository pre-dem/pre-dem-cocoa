# pre-dem-cocoa

[![Build Status](https://travis-ci.org/pre-dem/pre-dem-cocoa.svg?branch=master)](https://travis-ci.org/pre-dem/pre-dem-cocoa)
[![codecov](https://codecov.io/gh/pre-dem/pre-dem-cocoa/branch/master/graph/badge.svg)](https://codecov.io/gh/pre-dem/pre-dem-cocoa)
[![Latest Stable Version](https://img.shields.io/cocoapods/v/PreDemCocoa.svg)](https://github.com/pre-dem/pre-dem-cocoa/releases)
![Platform](http://img.shields.io/cocoapods/p/PreDemCocoa.svg)

## 简介

pre-dem-cocoa 是由[七牛云](https://www.qiniu.com)发起和维护的针对 iOS (Mac OS, Tv OS, Watch OS WIP) 等平台集用户体验监控及报障于一体的开源 SDK，用户可以将自定义数据上传到APM上进行分析

## 安装

使用 [CocoaPods](https://cocoapods.org) 进行安装

```ruby
pod "PreDemCocoa"
```

## 快速开始

- 创建APP
  首先到apm.qiniu.com 上登录并创建自己的APP，在配置信息中找到对应的APP KEY，以及消息上报的域名，填入到sdk中，

- 初始化

``` objc
    NSError *error;
    [PREDManager startWithAppKey:@"YOUR_APP_KEY" 
      serviceDomain:@"YOUR_REPORT_DOMAIN"];
```

初始化之后，SDK 便会自动定期从服务器更新配置信息，终端可根据配置来调整队列发送间隔时间

- 自定义事件

``` objc
    NSDictionary *dict = @{
                           @"PARAMETER_KEY1": @"PARAMETER_VALUE1",
                           @"PARAMETER_KEY2": @"PARAMETER_VALUE2"
                           };
    PREDEvent *event = [PREDEvent eventWithName:@"YOUR_EVENT_NAME" contentDic:dict];
    [PREDManager trackEvent:event];
```
自定义事件上报功能能够将您自定义的事件直接上报至服务器。

- 事务上报

开始一个事务
``` objc
PREDTransaction *transaction = [PREDManager transactionStart:@"test"];
```

将一个事务标识为完成并上传数据到服务器（！注意一个事务只能标识一次完成，之后应该释放该对象，多次标识完成会造成统计出现偏差）
``` objc
[transaction complete];
```

将一个事务标识为被取消并上传数据到服务器（！注意一个事务只能标识一次被取消，之后应该释放该对象，多次标识完成会造成统计出现偏差）
``` objc
[transaction cancelWithReason:@"test reason for cancelled transaction"];
```

将一个事务标识为失败并上传数据到服务器（！注意一个事务只能标识一次被取消，之后应该释放该对象，多次标识完成会造成统计出现偏差）
``` objc
[transaction failWithReason:@"test reason for failed transaction"];
```

## 示例代码
* 具体细节的一些配置 可参考 PreDemCocoaDemo/PreDemCocoaTests 下面的一些单元测试，以及源代码

## 常见问题

- iOS 9+ 强制使用https，需要在project build info 添加NSAppTransportSecurity类型Dictionary。在NSAppTransportSecurity下添加NSAllowsArbitraryLoads类型Boolean,值设为YES。 具体操作可参见 http://blog.csdn.net/guoer9973/article/details/48622823
- 如果碰到其他编译错误, 请参考 CocoaPods 的 [troubleshooting](http://guides.cocoapods.org/using/troubleshooting.html)

## 代码贡献

详情参考 [代码提交指南](https://github.com/pre-dem/pre-dem-cocoa/blob/master/Contributing.md).

## 贡献记录

- [所有贡献者](https://github.com/pre-dem/pre-dem-cocoa/contributors)

## 联系我们

- 如果需要帮助, 请提交工单 (在 portal 右侧点击咨询和建议提交工单, 或者直接向 support@qiniu.com 发送邮件)
- 如果有什么问题, 可以到问答社区提问, [问答社区](http://qiniu.segmentfault.com/)
- 如果发现了 bug, 欢迎提交 [issue](https://github.com/pre-dem/pre-dem-cocoa/issues)
- 如果有功能需求, 欢迎提交 [issue](https://github.com/pre-dem/pre-dem-cocoa/issues)
- 如果要提交代码, 欢迎提交 pull request
- 欢迎关注我们的 [微信](http://www.qiniu.com/#weixin) && [微博](http://weibo.com/qiniutek), 及时获取动态信息

## 代码许可

The MIT License (MIT). 详情见 [License 文件](https://github.com/qiniu/pre-dem-cocoa/blob/master/LICENSE).
