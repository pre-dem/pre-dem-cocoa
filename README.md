
[![Build Status](https://travis-ci.org/pre-dem/pre-dem-objc.svg?branch=master)](https://travis-ci.org/pre-dem/pre-dem-objc) [![codecov](https://codecov.io/gh/pre-dem/pre-dem-objc/branch/master/graph/badge.svg)](https://codecov.io/gh/pre-dem/pre-dem-objc)


# 注意事项
在更新工程对应的 CocoaPod 库之后需要在 `PreSniffSDK/Support/PreSniffObjcBase.debug.xcconfig` 和 `PreSniffSDK/Support/PreSniffObjcBase.release.xcconfig` 文件中分别添加 `PreSniffSDK/Pods/Target Support Files/Pods-PreSniffSDK/Pods-PreSniffSDK.debug.xcconfig` 和 `PreSniffSDK/Pods/Target Support Files/Pods-PreSniffSDK/Pods-PreSniffSDK.release.xcconfig` 相应的配置项，以便工程能够正常通过编译
