source 'https://github.com/CocoaPods/Specs.git'

use_frameworks!

abstract_target 'Astrolabe' do
  pod 'Astrolabe', :path => '.'
  pod 'Gnomon/JSON', '~> 2.1'

  target 'Demo' do
    platform :ios, '9.0'
  end

  target 'DemoTV' do
    platform :tvos, '9.0'
  end

  abstract_target 'Tests' do
    pod 'Astrolabe/Loaders', :path => '.'

    pod 'Nimble'
    pod 'RxBlocking'

    target 'iOSTests' do
      platform :ios, '9.0'
    end

    target 'tvOSTests' do
      platform :tvos, '9.0'
    end
  end
end
