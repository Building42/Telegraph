Pod::Spec.new do |s|
  s.name = 'Telegraph'
  s.version = '0.10'

  s.license = { :type => 'MPL2', :file => 'LICENSE' }
  s.summary = 'A Secure Web Server for iOS, tvOS and macOS'
  s.description = <<-DESC
      Telegraph is a Secure Web Server for iOS, tvOS and macOS written in Swift.
    DESC

  s.homepage = 'https://github.com/Building42/Telegraph'
  s.author = 'Building42'

  s.source = { :git => 'https://github.com/Building42/Telegraph.git', :tag => s.version }
  s.source_files = 'Sources/**/*.swift'
  s.xcconfig = { 'SWIFT_VERSION': '4.0' }

  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  s.dependency 'CocoaAsyncSocket', '~> 7.5'
  s.dependency 'HTTPParserC', '~> 2.7'
end
