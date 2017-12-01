Pod::Spec.new do |s|
  s.name         = "PreDemCocoa"
  s.version      = `sh utils.sh get-release-version`
  s.summary      = "A short description of PreDemCocoa."
  s.homepage     = "https://github.com/pre-dem/pre-dem-cocoa"
  s.license      = "MIT"
  s.author       = { "cnwangsiyu" => "cn.wangsiyu@gmail.com" }
  s.source       = { :git => "https://github.com/pre-dem/pre-dem-cocoa.git", :tag => "v#{s.version}" }
  s.ios.deployment_target = "8.0"

  s.default_subspec = "Core"

  s.subspec 'Core' do |cs|
    cs.source_files = "PreDemCocoa/**/*.{h,m,mm}"
    cs.public_header_files = 'PreDemCocoa/Public/*.h'
    cs.vendored_frameworks = 'Vendor/*.framework'
    cs.libraries  = "c++", "z"
    cs.resource_bundles = { 'PREDResources' => 'PreDemCocoa/Resources/*.plist' }
    cs.dependency "HappyDNS"
    cs.dependency "QNNetDiag"
    cs.dependency "Qiniu"
    cs.dependency "CocoaLumberjack"
    cs.dependency "UICKeyChainStore"
  end

  s.subspec 'Swift' do |ss|
    ss.dependency "PreDemCocoa/Core"
    ss.dependency "CocoaLumberjack/Swift"
    ss.source_files = "PreDemCocoa/**/*.{swift}"
  end
end
