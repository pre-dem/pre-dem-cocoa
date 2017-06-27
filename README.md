
[![Build Status](https://travis-ci.org/pre-dem/pre-dem-objc.svg?branch=master)](https://travis-ci.org/pre-dem/pre-dem-objc) [![codecov](https://codecov.io/gh/pre-dem/pre-dem-objc/branch/master/graph/badge.svg)](https://codecov.io/gh/pre-dem/pre-dem-objc)


# 注意事项
在更新工程对应的 CocoaPod 库之后需要在 `PreDemSDK/Support/PreDemObjcBase.debug.xcconfig` 和 `PreDemSDK/Support/PreDemObjcBase.release.xcconfig` 文件中分别添加 `PreDemSDK/Pods/Target Support Files/Pods-PreDemSDK/Pods-PreDemSDK.debug.xcconfig` 和 `PreDemSDK/Pods/Target Support Files/Pods-PreDemSDK/Pods-PreDemSDK.release.xcconfig` 相应的配置项，以便工程能够正常通过编译
