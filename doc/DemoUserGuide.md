# Demo User Guide

## http 性能统计

### 功能

该模块主要用于测量宿主 app 所产生的 http 请求相关的性能参数，然后将相关参数上报到服务端用于后续分析与展示

### 实现原理

http 性能参数测量主要通过代理宿主 app 网络请求的方式实现，当宿主 app 调用系统 API 进行网络请求发送时，SDK 会进行拦截，替代宿主 app 发送请求，测量相关性能参数并将结果返回给宿主 app，然后将相关数据存储在本地文件系统当中，每隔十秒发送一次数据，将所有新数据一次性发送。

### 使用方法

点击 Demo 界面中的 `点我发送一些网络请求` 按钮，此时 SDK 会触发一系列网络请求，SDK 会记录相关性能参数随后会将其发送，此时可以使用 wireshark 等抓包软件抓取相应数据包以验证相关行为是否正常。

- 发送的网络请求列表

| URLs |
| - |
| http://www.baidu.com |
| https://www.163.com |
| http://www.qq.com |
| https://www.qiniu.com |
| http://www.taobao.com |
| http://www.alipay.com |

- [点我查看请求细节](https://bitbucket.org/qiniuapm/pre-sniff-server/src/6076269673e814d9f45c5fd99a745bd8030503b6/doc/HTTPMonitor.md?at=master&fileviewer=file-view-default)

### 注意事项

- 当前实现无法监控 https 的 DNS 请求时间

## crash 日志收集上报

### 功能

该模块主要用于监控宿主 app 的 crash 情况，将 crash 报告上传到服务器以便进一步分析和展示

### 实现原理

crash 日志收集上报模块主要通过截获宿主 app crash 时的信号，记录当前 crash 相关信息并记录到本地文件系统，当宿主 app 下次启动时会检查本地 crash 日志并上传到服务器

### 使用方法

点击 Demo 界面中的 `点我触发一次 crash` 按钮，此时 demo 会发生闪退，SDK 会在此时将 crash 相关信息记录，再次启动 demo 此时 sdk 会将上次 crash 的日志上传服务器，此时可以通过 wireshark 等抓包软件抓取相应数据包以验证相关行为是否正常

- [点我查看请求细节](https://cf.qiniu.io/pages/viewpage.action?pageId=17648377)

### 注意事项

- 当设备连接 Xcode 调试的时候 SDK 无法收集 crash 日志

## 网络诊断

### 功能

该模块主要用于宿主 app 发生网络问题时由用户主动触发，sdk 会收集当前的详细网络诊断信息并上报服务器以便进行进一步分析和展示。

### 实现原理

网络诊断模块主要通过触发 `Ping`, `TcpPing`, `TraceRoute`, `NSLookup`, `Http` 五种诊断工具发送数据包并收集相关信息进行网络诊断，然后将相应诊断结果上传服务器。

### 使用方法

点击 Demo 界面中的 `点我诊断一下网络` 按钮触发一次网络诊断，Demo 会在所有诊断完成（需要十余秒到一分钟）之后将诊断结果整理上传，此时可以通过 wireshark 等抓包软件抓取相应数据包以验证相关行为是否正常

- [点我查看请求细节](https://bitbucket.org/qiniuapm/pre-sniff-server/src/6076269673e814d9f45c5fd99a745bd8030503b6/doc/NetDiagnoseAPI.md?at=master&fileviewer=file-view-default)

## 自定义事件

