## 日活统计

### 上报地址
通过config 配置进行上传日活数据，使用json 进行上报
`http(s)://domain/v1/:app_id/app-config/:platform`

### 上报间隔
config 一天内获取一次，启动时获取一次，异步获取更新，上次更新时间距离现在的时间不能超过24小时

### 上报内容

app_bundle_id     : String (app 包名，比如com.xxx.yyy)
app_name          : String (app 名字 比如王者荣耀)
app_version       : String 
device_model      : String
os_platform       : String
os_version        : String
sdk_version       : String
sdk_id            : String （通过sdk生成的唯一id）
device_id         : String  (设备唯一id，会有权限问题)

服务端需要根据客户端IP 分离出
country           : String
province          : String
city              : String
isp               : String


