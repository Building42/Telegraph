platform :ios, '9.0'
inhibit_all_warnings!
use_frameworks!

workspace 'Telegraph'

target 'iOS Example' do
  project 'iOS Example'

  pod 'Telegraph', path: '.'
end

target 'Telegraph' do
  project 'Telegraph'

  pod 'CocoaAsyncSocket'
  pod 'HTTPParserC'

  target 'TelegraphTests'
end
