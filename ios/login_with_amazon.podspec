#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'login_with_amazon'
  s.version          = '0.0.2'
  s.summary          = 'Implements the LoginWithAmazon SDK as a Flutter plugin.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://github.com/ened/login_with_amazon'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Sebastian Roth' => 'sebastian.roth@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'

  s.ios.frameworks  = 'Security', 'SafariServices'
  s.ios.deployment_target = '9.0'
  s.ios.vendored_frameworks = 'Frameworks/LoginWithAmazon.framework'
end
