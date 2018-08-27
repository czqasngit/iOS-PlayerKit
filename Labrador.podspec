#
# Be sure to run `pod lib lint Labrador.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Labrador'
  s.version          = '1.0.0'
  s.summary          = '[AudioPlayer, AudioQueue,Stream]Labrador is a complete stream/file audio player.'
  s.description      = 'A complete audio player with a modular design that can be replaced with different components to suit different needs. A decoder and two data providers have been implemented'
  s.homepage         = 'https://github.com/czqasngit/Labrador'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'czqasngit' => 'czqasn_6@163.com' }
  s.source           = { :git => 'https://github.com/czqasngit/Labrador.git', :tag => s.version.to_s }
  s.ios.deployment_target = '9.0'
  s.source_files = 'Labrador/Classes/**/*'
  s.public_header_files = 'Labrador/Classes/**/*.h'
  s.frameworks = 'AudioToolbox'
end
