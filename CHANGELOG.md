# Changelog

## [1.0.8](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.8) / 2018-03-26
- 增加 `transaction` 监控的支持
- 更新 demo
- 默认关闭 `breadcrumb` 数据上报

## [1.0.7](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.7) / 2018-02-23
- 修复 `http` 请求 `url` 为 `nil` 时会 crash 的问题
- 添加网络诊断功能中 `host` 字段上报

## [1.0.6](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.6) / 2018-01-10
- 将接口 `[PREDManager startWithAppKey:serviceDomain:complete:]` 改为 `[PREDManager startWithAppKey:serviceDomain:]`
- 将部分 log 打印更改为中文

## [1.0.5](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.5) / 2017-12-02
- lag 采集策略优化，避免出现过量采集情况
- 更新 demo 支持 webview 以及将 log 打印到界面

## [1.0.4](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.4) / 2017-12-01
- 更名为 `PreDemCocoa`
- 更新为 v2 接口，上报数据统一使用 `content` 存储非公共数据
- 添加面包屑采集
- log 采集增加回调接口
- 解决 log 采集与项目原有 `Cocoalumberjack` 冲突的问题

## [1.0.3](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.3) / 2017-12-01
- 去除 crash 和卡顿采集的本地符号化以提升性能
- 当服务器域名传入不正确时返回错误而不是直接抛出异常

## [1.0.2](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.2) / 2017-10-23
- 增加 log 采集的支持
- 增加发送事件之前的持久化存储
- 将自定义事件的发送由单条发送更改为批量发送
- 重构 SDK 的部分代码，提供更好的性能表现

## [1.0.2](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.2) / 2017-10-23
- 增加 log 采集的支持
- 增加发送事件之前的持久化存储
- 将自定义事件的发送由单条发送更改为批量发送
- 重构 SDK 的部分代码，提供更好的性能表现

## [1.0.1](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.1) / 2017-10-12
- 修复一些 log 采集的 bug
- 重构部分代码，提供更高的效率
- 一些稳定性提升

## [1.0.0](https://github.com/pre-dem/pre-dem-cocoa/releases/tag/v1.0.0) / 2017-08-23
* 初始化
