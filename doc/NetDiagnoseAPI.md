# Pre Sniff NetDiagnose API

API 域名：

* 开发服务器 `http://hriygkee.bq.cloudappl.com` (公网域名)
* 测试服务器 `http://jkbkolos.bq.cloudappl.com` (公网域名)

## 上报一条网络诊断数据

请求包：

```
POST v1/${app_id}/net-diags/${platform}
Content-Type: application/json
{
	AppId         string  `json:"app_id"`
	AppBundleId   string  `json:"app_bundle_id"`
	AppName       string  `json:"app_name"`
	AppVersion    string  `json:"app_version"`
	DeviceModel   string  `json:"device_model"`
	OsPlatform    string  `json:"os_platform"`
	OsVersion     string  `json:"os_version"`
	OsBuild       string  `json:"os_build"`
	SdkVersion    string  `json:"sdk_version"`
	SdkId         string  `json:"sdk_id"`
	DeviceId      string  `json:"device_id"`
	Tag           string  `json:"tag"`
	Manufacturer  string  `json:"manufacturer"`
	ResultID      string  `json:"result_id"`
	PingCode      int     `json:"ping_code"`
	PingIp        string  `json:"ping_ip"`
	PingSize      uint    `json:"ping_size"`
	PingMaxRtt    float64 `json:"ping_max_rtt"`
	PingMinRtt    float64 `json:"ping_min_rtt"`
	PingAvgRtt    float64 `json:"ping_avg_rtt"`
	PingLoss      int     `json:"ping_loss"`
	PingCount     int     `json:"ping_count"`
	PingTotalTime float64 `json:"ping_total_time"`
	PingStddev    float64 `json:"ping_stddev"`
	TcpCode       int     `json:"tcp_code"`
	TcpIp         string  `json:"tcp_ip"`
	TcpMaxTime    float64 `json:"tcp_max_time"`
	TcpMinTime    float64 `json:"tcp_min_time"`
	TcpAvgTime    float64 `json:"tcp_avg_time"`
	TcpLoss       int     `json:"tcp_loss"`
	TcpCount      int     `json:"tcp_count"`
	TcpTotalTime  float64 `json:"tcp_total_time"`
	TcpStddev     float64 `json:"tcp_stddev"`
	TrCode        int     `json:"tr_code"`
	TrIp          string  `json:"tr_ip"`
	TrContent     string  `json:"tr_content"`
	DnsRecords    string  `json:"dns_records"`
	HttpCode      int     `json:"http_code"`
	HttpIp        string  `json:"http_ip"`
	HttpDuration  float64 `json:"http_duration"`
	HttpBodySize  int     `json:"http_body_size"`
}
```

返回包：

- 如果请求成功，返回包含如下内容的 JSON 字符串（已格式化，便于阅读）：
```
201 
{}
```

- 如果请求失败，返回包含如下内容的JSON字符串（已格式化，便于阅读）：
```
{
    "error_message":    ${Error} // string
    "error_code":       ${ErrorCode}
}
```
