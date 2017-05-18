inhibit_all_warnings!
use_frameworks!

workspace 'Telegraph'

# Frameworks

target 'Telegraph iOS' do
  platform :ios, '9.0'
  project 'Telegraph'
  target 'TelegraphTests'

  pod 'CocoaAsyncSocket'
  pod 'HTTPParserC'
end

target 'Telegraph tvOS' do
  platform :tvos, '9.0'
  project 'Telegraph'

  pod 'CocoaAsyncSocket'
  pod 'HTTPParserC'
end

target 'Telegraph macOS' do
  platform :osx, '10.10'
  project 'Telegraph'

  pod 'CocoaAsyncSocket'
  pod 'HTTPParserC'
end

# Examples

target 'iOS Example' do
  platform :ios, '9.0'
  project 'Examples/iOS Example'

  pod 'Telegraph', path: '.'
end

target 'tvOS Example' do
  platform :tvos, '9.0'
  project 'Examples/tvOS Example'

  pod 'Telegraph', path: '.'
end

target 'macOS Example' do
  platform :osx, '10.10'
  project 'Examples/macOS Example'

  pod 'Telegraph', path: '.'
end
