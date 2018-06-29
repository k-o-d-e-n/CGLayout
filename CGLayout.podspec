#
# Be sure to run `pod lib lint CGLayout.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CGLayout'
  s.version          = '0.6.6'
  s.summary          = 'Constraint-based autolayout system written on Swift. Not Autolayout wrapper.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Powerful autolayout framework, that can manage UIView(NSView), CALayer and not rendered views. Has cross-hierarchy coordinate space. Implementation performed on rect-based constraints. Fast, asynchronous, declarative, cacheable, extensible. Supported iOS, macOS, tvOS, Linux.'

  s.homepage         = 'https://github.com/k-o-d-e-n/CGLayout'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'k-o-d-e-n' => 'koden.u8800@gmail.com' }
  s.source           = { :git => 'https://github.com/k-o-d-e-n/CGLayout.git', :tag => '0.6.5_beta' }
  s.social_media_url = 'https://twitter.com/K_o_D_e_N'

  s.ios.deployment_target = '9.0'
  s.tvos.deployment_target = '10.0'
  s.osx.deployment_target = '10.10'

  s.source_files = 'Sources/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CGLayout' => ['CGLayout/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
