Pod::Spec.new do |spec|
  spec.name         = "QZCache"
  spec.version      = "1.0.0"
  spec.summary      = "A short description of QZCache SDK for iOS."
  spec.description  = <<-DESC
            TopOn SDK for developer
                   DESC
  spec.homepage     = "https://github.com/huqinzhi/QZCache"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "hqz" => "576188937@qq.com" }
  spec.source       = { :git => "https://github.com/huqinzhi/QZCache.git", :tag => spec.version }
  spec.platform     = :ios, '8.0'
  spec.ios.deployment_target = '8.0'
  spec.requires_arc = true
  spec.frameworks = 'SystemConfiguration','Foundation'
  
  spec.user_target_xcconfig =   {'OTHER_LDFLAGS' => ['-lObjC']}
  spec.libraries = 'c++', 'z'
  spec.default_subspecs = 'QZCache'

  spec.subspec 'QZCache' do |ss|
     ss.ios.deployment_target = '8.0'
     ss.source_files = 'QZCacheGroup/GN*.h','QZCacheGroup/GN*.m','QZCacheGroup/QZ*.h','QZCacheGroup/QZ*.m'
  end

end
