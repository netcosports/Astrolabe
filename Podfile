
use_modular_headers!

abstract_target 'Astrolabe' do
  pod 'Astrolabe', :path => '.'

  target 'Demo' do
    platform :ios, '11.0'
    pod 'SnapKit'
  end

  target 'DemoTV' do
    platform :tvos, '11.0'
    pod 'SnapKit'
  end

  abstract_target 'Tests' do
    pod 'Astrolabe', :path => '.'

    pod 'Quick'
    pod 'Nimble'
    pod 'RxBlocking'
    pod 'RxTest'

    target 'iOSTests' do
      platform :ios, '11.0'
    end

    target 'tvOSTests' do
      platform :tvos, '11.0'
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
