Pod::Spec.new do |spec|

  spec.name         = "STLifeCircle"
  spec.version      = "0.0.1"
  spec.summary      = "STLifeCircle 说明."
  spec.description      = <<-DESC
  STLifeCircle long description of the pod here.
  DESC
  
  spec.homepage         = 'http://github.com/coder/STLifeCircle'
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author             = { "coder" => "coder@gmail.com" }
  spec.ios.deployment_target = '9.0'

  spec.source       = { :git => "https://github.com/stephen5652/STLifeCircle.git", :tag => "#{spec.version}" }
  
  
  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'STLifeCircle/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "STLifeCircle/Exclude" #排除文件
  
  spec.project_header_files = 'STLifeCircle/Private/**/*.{h}'
  spec.public_header_files = 'STLifeCircle/Public/**/*.h' #此处放置组件的对外暴漏的头文件
  
  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'STLifeCircle/Private/**/*.framework'
  #spec.vendored_libraries = 'STLifeCircle/Private/**/*.a'
  
  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源

  #  spec.resources = ["STLifeCircle/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'STLifeCircle' => ['STLifeCircle/Assets/*.xcassets', "STLifeCircle/{Public,Private}/**/*.{png,jpg,font,json}"]
  #  }
  

  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"
  
  
  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.requires_arc = true
  
  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

  # 其他依赖pod
   spec.dependency "STAnnotation"

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
