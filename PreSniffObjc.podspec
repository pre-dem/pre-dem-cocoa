Pod::Spec.new do |s|
  s.name         = "PreSniffObjc"
  s.version      = "1.0.0"
  s.summary      = "A short description of PreSniffObjc."
  s.homepage     = "https://github.com/pre-sniff/pre-sniff-objc"
  s.license      = "MIT"
  s.author       = { "cnwangsiyu" => "cn.wangsiyu@gmail.com" }


  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"


  s.source       = { :git => "https://github.com/pre-sniff/pre-sniff-objc.git", :tag => "v#{s.version}" }
  s.source_files = "PreSniffObjc/**/*.{h,m,mm}"
  s.public_header_files = 'PreSniffObjc/Public/*.h'
  s.vendored_frameworks = 'Vendor/*.framework'
  s.frameworks = "AssetsLibrary", "CoreTelephony", "CoreText", "CoreGraphics", "Foundation", "MobileCoreServices", "Photos", "QuartzCore", "QuickLook", "Security", "SystemConfiguration", "UIKit"
  s.libraries  = "c++", "z"
  s.resource_bundles = { 'PRESResources' => 'PreSniffObjc/Resources/*.plist' }

  s.dependency "HappyDNS"
  s.dependency "QNNetDiag"

end
