Pod::Spec.new do |s|
  s.name         = "PreDemCocoa"
  s.version      = `sh utils.sh get-release-version`
  s.summary      = "A short description of PreDemCocoa."
  s.homepage     = "https://github.com/pre-dem/pre-dem-cocoa"
  s.license      = "MIT"
  s.author       = { "cnwangsiyu" => "cn.wangsiyu@gmail.com" }


  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/pre-dem/pre-dem-cocoa.git", :tag => "v#{s.version}" }
  s.source_files = "PreDemCocoa/**/*.{h,m,mm,swift}"
  s.public_header_files = 'PreDemCocoa/Public/*.h'
  s.vendored_frameworks = 'Vendor/*.framework'
  s.libraries  = "c++", "z"
  s.resource_bundles = { 'PREDResources' => 'PreDemCocoa/Resources/*.plist' }
  s.dependency "HappyDNS"
  s.dependency "QNNetDiag"
  s.dependency "Qiniu"
  s.dependency "CocoaLumberjack"
  s.dependency "CocoaLumberjack/Swift"
  s.dependency "UICKeyChainStore"
  s.dependency "WKWebViewWithURLProtocol"

end
