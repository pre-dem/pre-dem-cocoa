## 日活统计

### 上报地址
通过config 配置进行上传日活数据，使用json 进行上报
`http(s)://domain/v1/:app_id/app-config/:platform`

### 上报间隔
config 一天内获取一次，启动时获取一次，异步获取更新，上次更新时间距离现在的时间不能超过24小时

### 上报内容

```
{
	AppId        string `json:"app_id"`
	AppBundleId  string `json:"app_bundle_id"`
	AppName      string `json:"app_name"`
	AppVersion   string `json:"app_version"`
	DeviceModel  string `json:"device_model"`
	OsPlatform   string `json:"os_platform"`
	OsVersion    string `json:"os_version"`
	OsBuild      string `json:"os_build"`
	SdkVersion   string `json:"sdk_version"`
	SdkId        string `json:"sdk_id"`
	DeviceId     string `json:"device_id"`
	Tag          string `json:"tag"`
	Manufacturer string `json:"manufacturer"`
}
```


