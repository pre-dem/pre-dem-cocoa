Pod::Spec.new do |s|
  s.name         = "PreDemObjc"
  s.version      = "1.0.0"
  s.summary      = "A short description of PreDemObjc."
  s.homepage     = "https://github.com/pre-dem/pre-dem-objc"
  s.license      = "MIT"
  s.author       = { "cnwangsiyu" => "cn.wangsiyu@gmail.com" }


  s.ios.deployment_target = "8.0"

  s.source       = { :git => "https://github.com/pre-dem/pre-dem-objc.git", :tag => "v#{s.version}" }
  s.source_files = "PreDemObjc/**/*.{h,m,mm}"
  s.public_header_files = 'PreDemObjc/Public/*.h'
  s.vendored_frameworks = 'Vendor/*.framework'
  s.frameworks = "AssetsLibrary", "CoreTelephony", "CoreText", "CoreGraphics", "Foundation", "MobileCoreServices", "Photos", "QuartzCore", "QuickLook", "Security", "SystemConfiguration"
  s.libraries  = "c++", "z"
  s.resource_bundles = { 'PREDResources' => 'PreDemObjc/Resources/*.plist' }

  non_arc_files = ['PreDemObjc/Helper/KeychainItemWrapper.{h,m}']
  s.exclude_files = non_arc_files
  s.subspec 'no-arc' do |sna|
    sna.requires_arc = false
    sna.source_files = non_arc_files
  end

  s.dependency "HappyDNS"
  s.dependency "QNNetDiag"
  s.dependency "Qiniu"

end
