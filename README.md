# pre-dem-cocoa

[![Build Status](https://travis-ci.org/pre-dem/pre-dem-cocoa.svg?branch=master)](https://travis-ci.org/pre-dem/pre-dem-cocoa)
[![codecov](https://codecov.io/gh/pre-dem/pre-dem-cocoa/branch/master/graph/badge.svg)](https://codecov.io/gh/pre-dem/pre-dem-cocoa)

## 简介

pre-dem-cocoa 是由[七牛云](https://www.qiniu.com)发起和维护的针对 iOS (Mac OS, Tv OS, Watch OS WIP) 等平台集用户体验监控及报障于一体的开源 SDK，具有无埋点集成，轻量级，高性能等优点

## 功能清单

| 功能 | 版本 |
| - | - |
| crash 监控 | v1.0.0 |
| HTTP 性能监控 | v1.0.0 |
| UI 卡顿监控 | v1.0.0 |
| 网络诊断 | v1.0.0 |
| 自定义事件上报 | v1.0.0 |
| log 上报 | v1.0.2 |

## 安装

使用 [CocoaPods](https://cocoapods.org) 进行安装

```ruby
pod "PreDemObjc"
```

## 快速开始

- 初始化

``` objc
    NSError *error;
    [PREDManager startWithAppKey:@"YOUR_APP_KEY"
                   serviceDomain:@"YOUR_REPORT_DOMAIN"
                        complete:^(BOOL succeess, NSError * _Nullable error) {
                            if (error) {
                                NSLog(@"initialize PREDManager error: %@", error);
                            }
                        }];
```

初始化之后，SDK 便会自动采集包括 crash、HTTP 请求等监控数据并上报到您指定的服务器

- 网络诊断

``` objc
    [PREDManager  diagnose:@"YOUR_SERVER"
                  complete:^(PREDNetDiagResult * _Nonnull result) {
        NSLog(@"new diagnose completed with result:\n %@", result);
    }];
```

网络诊断功能会使用包括 ping, traceroute 等一系列网络工具对您指定的服务器进行网络诊断并将诊断结果上传服务器。

- log 上报

log 打印
``` objc
    // 你可以使用你需要的级别打印相关的 log
    PREDLogVerbose(@"verbose log test");
    PREDLogDebug(@"debug log test");
    PREDLogInfo(@"info log test");
    PREDLogWarn(@"warn log test");
    PREDLogError(@"error log test");
```

log 上报
``` objc
    // 开始上报指定级别及以上的 log
    [PREDLogger startCaptureLogWithLevel:PREDLogLevelXXX];
    // 停止上报
    [PREDLogger stopCaptureLog];
```

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
