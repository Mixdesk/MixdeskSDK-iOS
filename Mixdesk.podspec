# coding: utf-8
#
# Be sure to run `pod lib lint Mixdesk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Mixdesk"
  s.version          = "1.0.8"
  s.summary          = "Mixdesk官方 SDK for iOS"
  s.description      = "Mixdesk官方的 iOS SDK, 可接入Mixdesk系统"

  s.homepage         = "https://github.com/Mixdesk/MixdeskSDK-iOS"
  s.license          = 'MIT'
  s.author           = { "songuu" => "1101309860@qq.com" }
  s.source           = { :git => "https://github.com/Mixdesk/MixdeskSDK-iOS.git", :tag => "v1.0.8" }
  s.social_media_url = "https://mixdesk.com"
  s.documentation_url = "https://github.com/Mixdesk/MixdeskSDK-iOS/wiki"
  s.platform     = :ios, '10.0'
  s.requires_arc = true
  s.pod_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }

  s.subspec 'MixdeskSDK' do |ss|
    ss.frameworks =  'AVFoundation', 'CoreTelephony', 'SystemConfiguration', 'MobileCoreServices'
    ss.vendored_frameworks = 'Mixdesk-SDK-files/MixdeskSDK.framework'
    ss.libraries  =  'sqlite3', 'icucore', 'stdc++'
    ss.xcconfig = { "FRAMEWORK_SEARCH_PATHS" => "${PODS_ROOT}/Mixdesk/Mixdesk-SDK-files"}
  end
  s.subspec 'MXChatViewController' do |ss|
    ss.dependency 'Mixdesk/MixdeskSDK'
    # avoid compile error when using 'use frameworks!',because this header is c++, but in unbrellar header don't know how to compile, there's no '.mm' file in the context.
    ss.private_header_files = 'Mixdesk-SDK-files/MXChatViewController/Vendors/VoiceConvert/amrwapper/wav.h'
    ss.source_files = 'Mixdesk-SDK-files/MixdeskSDKViewInterface/*.{h,m}', 'Mixdesk-SDK-files/MXChatViewController/**/*.{h,m,mm,cpp}', 'Mixdesk-SDK-files/MixdeskMessageForm/**/*.{h,m}', 'Mixdesk-SDK-files/Notification/*.{h,m}'
    ss.vendored_libraries = 'Mixdesk-SDK-files/MXChatViewController/Vendors/MLAudioRecorder/amr_en_de/lib/libopencore-amrnb.a', 'Mixdesk-SDK-files/MXChatViewController/Vendors/MLAudioRecorder/amr_en_de/lib/libopencore-amrwb.a'
    #ss.preserve_path = '**/libopencore-amrnb.a', '**/libopencore-amrwb.a'
    ss.xcconfig = { "LIBRARY_SEARCH_PATHS" => "\"$(PODS_ROOT)/Mixdesk/Mixdesk-SDK-files\"" }
    ss.resources = 'Mixdesk-SDK-files/MXChatViewController/Assets/MXChatViewAsset.bundle'
  end
end
