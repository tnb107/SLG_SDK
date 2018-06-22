#
# Be sure to run `pod lib lint sdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'sdk'
  s.version          = '0.1.0'
  s.summary          = 'A short description of sdk.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/tnb107/SLG_SDK'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'tnb107' => 'nguyenbathanhth@gmail.com' }
  s.source           = { :git => 'https://github.com/tnb107/SLG_SDK.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  #s.ios.deployment_target = '10.3'
  s.ios.deployment_target = '9.0'


  s.source_files = 'sdk/Classes/*.swift'
  
  # s.resource_bundles = {
  #   'sdk' => ['sdk/Assets/*.png',]
  # }

  s.ios.resource_bundles = {
    'sdk' => ['sdk/Assets/*','sdk/Classes/*.xib']
  }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.frameworks = 'SafariServices', 'SystemConfiguration', 'Security'

  # s.dependency 'AFNetworking', '~> 2.3'
  #s.libraries = 'c++', 'z'
  s.vendored_frameworks = 'GoogleSignIn.framework', 'Analytics/*.framework' , 'Messaging/*.framework'

  s.dependency 'SwiftyJSON', '~> 4.0.0'
  s.dependency 'ObjectMapper', '~> 3.0'
  s.dependency 'Alamofire', '~> 4.5'
  s.dependency 'SVProgressHUD'
  s.dependency 'SDWebImage', '~> 4.0'
  s.dependency 'CRToast', '~> 0.0.7'
  s.dependency 'Bolts', '~> 1.8.4'
  s.dependency 'FBSDKCoreKit', '~> 4.28.0'
  s.dependency 'FBSDKLoginKit', '~> 4.28.0'
  s.dependency 'FBSDKShareKit', '~> 4.28.0'
  s.dependency 'GTMOAuth2', '~> 1.1.5'
  s.dependency 'GTMSessionFetcher', '~> 1.1.12'
  #s.dependency 'GoogleToolboxForMac', '~> 2.1.3'
  s.pod_target_xcconfig = {
     'OTHER_LDFLAGS' => '$(inherited) -ObjC'
  }
end
