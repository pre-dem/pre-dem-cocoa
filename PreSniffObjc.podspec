Pod::Spec.new do |s|
  s.name         = "PreSniffObjc"
  s.version      = "1.0.0"
  s.summary      = "A short description of PreSniffObjc."
  s.homepage     = "https://github.com/pre-sniff/pre-sniff-objc"
  s.license      = "MIT"
  s.author       = { "cnwangsiyu" => "cn.wangsiyu@gmail.com" }


  s.ios.deployment_target = "7.0"
  s.osx.deployment_target = "10.10"


  s.source       = { :git => "https://github.com/pre-sniff/pre-sniff-objc.git", :tag => "#{s.version}" }
  s.source_files = "PreSniffObjc/**/*.{h,m,mm}"
  s.vendored_frameworks = 'Vendor/*.framework'


  s.pod_target_xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => 'BITHOCKEY_VERSION="@\""$(VERSION_STRING)"\"" BITHOCKEY_BUILD="@\""$(BUILD_NUMBER)"\"" BITHOCKEY_C_VERSION="\""$(VERSION_STRING)"\"" BITHOCKEY_C_BUILD="\""$(BUILD_NUMBER)"\""', 'OTHER_LDFLAGS' => '-ObjC'}

  s.frameworks = "AssetsLibrary", "CoreTelephony", "CoreText", "CoreGraphics", "Foundation", "MobileCoreServices", "Photos", "QuartzCore", "QuickLook", "Security", "SystemConfiguration", "UIKit"
  s.libraries  = "c++", "z"

  s.dependency "HappyDNS"

end
