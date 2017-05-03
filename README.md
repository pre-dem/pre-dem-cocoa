
[![Build Status](https://travis-ci.com/qbox/pre-sniff-objc.svg?token=4UdMWHQptsJA46XUVYqy&branch=master)](https://travis-ci.com/qbox/pre-sniff-objc)  [![Coverage](https://codecov.io/gh/huandeheng/pre-sniff-objc/coverage.svg?branch=master&token=wS3Omw7Y9T)](https://codecov.io/gh/huangdeheng/pre-sniff-objc)


# 注意事项
在更新工程对应的 CocoaPod 库之后需要在 `PreSniffSDK/Support/HockeySDKBase.debug.xcconfig` 和 `PreSniffSDK/Support/HockeySDKBase.release.xcconfig` 文件中分别添加 `PreSniffSDK/Pods/Target Support Files/Pods-PreSniffSDK/Pods-PreSniffSDK.debug.xcconfig` 和 `PreSniffSDK/Pods/Target Support Files/Pods-PreSniffSDK/Pods-PreSniffSDK.release.xcconfig` 相应的配置项，以便工程能够正常通过编译