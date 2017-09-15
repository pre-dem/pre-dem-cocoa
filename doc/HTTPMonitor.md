<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](https://github.com/thlorenz/doctoc)*

- [Pre Sniff Server HTTP Monitor Spec](#pre-sniff-server-http-monitor-spec)
  - [API](#api)
    - [上报监控数据](#%E4%B8%8A%E6%8A%A5%E7%9B%91%E6%8E%A7%E6%95%B0%E6%8D%AE)
  - [行为约定](#%E8%A1%8C%E4%B8%BA%E7%BA%A6%E5%AE%9A)
    - [log 目录结构及索引文件](#log-%E7%9B%AE%E5%BD%95%E7%BB%93%E6%9E%84%E5%8F%8A%E7%B4%A2%E5%BC%95%E6%96%87%E4%BB%B6)
    - [log 行为约定](#log-%E8%A1%8C%E4%B8%BA%E7%BA%A6%E5%AE%9A)
    - [轮询上报](#%E8%BD%AE%E8%AF%A2%E4%B8%8A%E6%8A%A5)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

# Pre Sniff Server HTTP Monitor Spec

## API

API域名: 

* 开发服务器 `http://hriygkee.bq.cloudappl.com` (公网域名)
* 测试服务器 `http://jkbkolos.bq.cloudappl.com` (公网域名)

### 上报监控数据

请求包:
```
POST v1/${app_id}/http-stats/${platform}
Content-Type: application/x-gzip
Content-Encoding: gzip
Body: ${Content}
```

返回包:

- 如果请求成功，返回包含如下内容的 JSON 字符串（已格式化，便于阅读）：
```
201
{}
```

- 如果请求失败，返回包含如下内容的JSON字符串（已格式化，便于阅读）：
```
{
    "error_message":    ${ErrorMessage} // string
    "error_code":   ${ErrorCode} // string
}
```

* `<Content>`: 上报信息正文，格式：
```
${value0}\t${value1}\t${value2}\t${value3}\n
${value0}\t${value1}\t${value2}\t${value3}\n
...
```
当字段值不存在时使用 `-` 填充相应字段进行上报
数据使用 gzip 进行压缩

* 上报数据结构
```
{	
	AppId             string `json:"app_id"`
	AppBundleId       string `json:"app_bundle_id"`
	AppName           string `json:"app_name"`
	AppVersion        string `json:"app_version"`
	DeviceModel       string `json:"device_model"`
	OsPlatform        string `json:"os_platform"`
	OsVersion         string `json:"os_version"`
	OsBuild           string `json:"os_build"`
	SdkVersion        string `json:"sdk_version"`
	SdkId             string `json:"sdk_id"`
	DeviceId          string `json:"device_id"`
	Tag               string `json:"tag"`
	Manufacturer      string `json:"manufacturer"`
	Domain            string `json:"domain"` // 请求的 Domain Name
	Path              string `json:"path"` // 请求的 Path
	Method            string `json:"method"` // 请求使用的 HTTP 方法，如 POST
	HostIP            string `json:"host_ip"` // 实际发生请求的主机 IP 地址
	StatusCode        int64  `json:"status_code"` // 服务器返回的 HTTP 状态码
	StartTimestamp    uint64 `json:"start_timestamp"` // 请求开始时间戳，单位是 Unix ms
	ResponseTimeStamp uint64 `json:"response_time_stamp"` // 服务器返回 Response 的时间戳，
	EndTimestamp      uint64 `json:"end_timestamp"` // 请求结束时间戳，单位是 Unix ms
	DnsTime           uint64 `json:"dns_time"` // 请求的 DNS 解析时间, 单位是 ms
	DataLength        uint64 `json:"data_length"` // 请求返回的 data 的总长度，单位是 
	NetworkErrorCode  int64  `json:"network_error_code"` // 请求发生网络错误时的错误码
	NetworkErrorMsg   string `json:"network_error_msg"` // 请求发生网络错误时的错误信息
}
```

## 行为约定

### log 目录结构及索引文件

```
// 一个完整的 log 目录信息结构如下
.
|- index.json // 滚动 log 文件对应的索引文件
|- log.1      // 每个 log 以文件大小作为上线
|- log.2
|- log.3
|- ...
```

```
// index 文件需要包含的基本信息
{
  read_file_index: 1,       // 最近一次被读取的文件
  read_file_position: 324,  // 最近一次读取到的位置
  write_file_index: 2,      // 最近一次写入的文件
  write_file_position: 111  // 最近一次写入到的位置
}
```

### log 行为约定

- 使用滚动 log 文件方式切换记录
  - 单个 log 文件以文件大小作为上限
  - 当一个文件写满后，创建新的文件
  - 当启动 App 时发现有 log 文件还未上报，创建新的文件写入 log 而不在原有文件做追加
- log 记录要保证读写原子性
  - I/O 操作要有独立线程
  - 可考虑维持一个读写的执行队列
- log 文件清除
  - 当 read_file_index 递增触发时，将小于等于该 index 的所有 log 文件清除
  
  **log 文件数量不超过 100 个，当累积文件数达到 100 时新写入文件从最老的 log 文件开始替换过期 log**
  
  **单个 log 文件大小不超过 64 KB**
  

### 轮询上报

- 计时器
  - App 启动后，开启轮询计时器
  - 进入后台时停止计时器
  - 从后台回到前台时，恢复计时器
- 上报过程出现异常
  - 上报失败时，要将 index.json 的 read 信息恢复为上报读取前的数值
  - 上报失败时，不对 log 文件做清除操作