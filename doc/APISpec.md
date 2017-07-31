# API 规范

### 基本格式

http(s)://domain/v1/:app_id/functional-path?query

Authorization：SHA2(url:sk)
*注意 这里的url 不含scheme*

如果忽略鉴权，这里可以为空

*TODO* 如果需要，可以在query里加入utc 时间

除了自定义的上报，都会带上platform, platform 用字符串表示，i(ios)和a(android)

客户在使用时，需要配置两个参数，app_key 以及域名

app_key 分为两部分，app_id和sk

服务端根据app_id 找寻对应的app

### 基本功能

#### 崩溃上报

http(s)://domain/v1/:app_id/crashes/:platform

#### Http监控

http(s)://domain/v1/:app_id/http-stats/:platform

#### 网络诊断

http(s)://domain/v1/:app_id/net-diags/:platform

#### 服务配置

http(s)://domain/v1/:app_id/app-config/:platform

#### 自定义上报

http(s)://domain/v1/:app_id/events/:event



