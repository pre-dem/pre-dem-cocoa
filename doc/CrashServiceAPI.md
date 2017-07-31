# Pre Sniff Server Crash Report Service Spec

## API

API 域名:

* 开发服务器 `http://hriygkee.bq.cloudappl.com` (公网域名)
* 测试服务器 `http://jkbkolos.bq.cloudappl.com` (公网域名)

### 获取崩溃日志上传 token 接口

请求包：

```
GET /v1/${app_id}/crash-report-token/${platform}?md5=${md5}
```

`${platform}` 目前支持两个平台，其中 `i` 代表 `iOS`, `a` 代表 `android`

例：

```
GET /v1/f127c8d8f9ede0f464e80f5f4b46658/crash-report-token/i?md5=${af47219ebc749eab8127caedba}
```

- 若获取崩溃报告成功，返回：

```
200
{
	"message": "ok",
	"token": ${UploadToken}  // string
	"key": ${FileKey}
}
```

- 若获取失败，返回：

```
400
{
	"error_code": ${ErrorCode},  // long
	"error_message": ${ErrorMessage} // string
}
```

### 上报崩溃日志描述信息

请求包:

```
POST v1/${app_id}/crashes/${platform}
Content-Type: application/json
Body:
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
	ReportUUID   string `json:"report_uuid"`
	CrashLogKey  string `json:"crash_log_key"`
	Manufacturer string `json:"manufacturer"`
	StartTime    string `json:"start_time"`
	CrashTime    string `json:"crash_time"`
}
```

`${platform}` 目前支持两个平台，其中 `i` 代表 `iOS`, `a` 代表 `android`

例：

```
POST /v1/f127c8d8f9ede0f464e80f5f4b46658/crashes/i
```

返回包：

- 若上传崩溃描述信息成功，返回：

```
200
{
	"message": "ok"
}
```

- 若上传崩溃描述信息失败，返回：

```
400
{
	"error_code": ${ErrorCode},  // long
	"error_message": ${ErrorMessage} // string
}
```
