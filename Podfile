inhibit_all_warnings!
use_frameworks!

workspace 'Telegraph'

target 'Telegraph' do
  platform :ios, '9.0'

  project 'Telegraph'
  target 'TelegraphTests'

  pod 'CocoaAsyncSocket'
  pod 'HTTPParserC'
end

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
