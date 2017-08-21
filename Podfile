source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

abstract_target 'Astrolabe' do
  pod 'Astrolabe', :path => '.'
  pod 'Gnomon', :git => 'https://github.com/netcosports/Gnomon', :branch => 'swift4'
  pod 'SnapKit', :git => 'https://github.com/SnapKit/SnapKit', :branch => 'swift-4'

  target 'Demo' do
    platform :ios, '9.0'
  end

  target 'DemoTV' do
    platform :tvos, '9.0'
  end

  abstract_target 'Tests' do
    pod 'Astrolabe/Loaders', :path => '.'

    pod 'Nimble', :git => 'https://github.com/Quick/Nimble.git'
    pod 'RxBlocking', '4.0.0-alpha.1'

    target 'iOSTests' do
      platform :ios, '9.0'
    end

    target 'tvOSTests' do
      platform :tvos, '9.0'
    end
  end
end
