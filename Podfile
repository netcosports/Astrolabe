#source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

abstract_target 'Astrolabe' do
  pod 'Astrolabe', :path => '.'
  pod 'Gnomon', :git => 'git@github.com:netcosports/Gnomon.git', :branch => 'rolandgarros'
  pod 'Gnomon/Decodable', :git => 'git@github.com:netcosports/Gnomon.git', :branch => 'rolandgarros'

  target 'Demo' do
    platform :ios, '12.0'
    pod 'SnapKit'
  end

  target 'DemoTV' do
    platform :tvos, '12.0'
    pod 'SnapKit'
  end

  abstract_target 'Tests' do
    pod 'Astrolabe/Loaders', :path => '.'

    pod 'Quick'
    pod 'Nimble'
    pod 'RxBlocking'
    pod 'RxTest'

    target 'iOSTests' do
      platform :ios, '12.0'
    end

    target 'tvOSTests' do
      platform :tvos, '12.0'
    end
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_ACTIVE_COMPILATION_CONDITIONS'] = '$(inherited) TEST'
    end
  end
end
