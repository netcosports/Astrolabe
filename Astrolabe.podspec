Pod::Spec.new do |s|
  s.name = 'Astrolabe'
  s.version = '6.0'
  s.summary = 'Cells management library'

  s.homepage = 'https://github.com/netcosports/Astrolabe'
  s.license = { :type => "MIT" }
  s.author = {
    'Sergei Mikhan' => 'sergei@netcosports.com',
    'Vladimir Burdukov' => 'vladimir.burdukov@netcosports.com'
  }
  s.source = { :git => 'https://github.com/netcosports/Astrolabe.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'
  s.tvos.deployment_target = '11.0'

  s.swift_versions = ['5.1', '5.2', '5.3']

  s.source_files = 'Sources/Core/*.swift'
  s.tvos.exclude_files = ['Sources/Core/*PagerSource.swift', 'Sources/Core/*PagerCollectionViewCell.swift']

  s.dependency 'RxSwift', '~> 6'
  s.dependency 'RxCocoa', '~> 6'

end
