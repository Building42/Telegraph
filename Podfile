source 'https://github.com/CocoaPods/Specs.git'

inhibit_all_warnings!
use_frameworks!

workspace 'Telegraph'

# Dependencies

pod 'CocoaAsyncSocket'
pod 'HTTPParserC'

# Telegraph

target 'Telegraph iOS' do
  platform :ios, '9.0'
  target 'Telegraph Tests'
end

target 'Telegraph tvOS' do
  platform :tvos, '9.0'
end

target 'Telegraph macOS' do
  platform :osx, '10.10'
end

# Examples

target 'iOS Example' do
  platform :ios, '9.0'
  project 'Examples/iOS Example'
end

target 'tvOS Example' do
  platform :tvos, '9.0'
  project 'Examples/tvOS Example'
end

target 'macOS Example' do
  platform :osx, '10.10'
  project 'Examples/macOS Example'
end
