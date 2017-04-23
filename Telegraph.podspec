Pod::Spec.new do |s|
  s.name = 'Telegraph'
  s.version = '0.1.0'

  s.license = { :type => 'MPL2', :file => 'LICENSE' }
  s.summary = 'A Secure Web Server for iOS'
  s.description = <<-DESC
      Telegraph is a Secure Web Server for iOS written in Swift.
    DESC

  s.homepage = 'https://github.com/Building42/Telegraph'
  s.author = 'Building42'

  s.source = { :git => 'https://github.com/Building42/Telegraph.git', :tag => s.version }

  s.ios.deployment_target = '9.0'
  s.source_files = 'Telegraph/Source/**/*.swift'

  s.dependency 'CocoaAsyncSocket', '~> 7.5.1'
  s.dependency 'HTTPParserC', '~> 2.7.1'
end
