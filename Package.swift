// swift-tools-version:5.0

import PackageDescription

extension Target {
  static func astrolabe() -> Target {
    #if os(tvOS)
      return .target(name: "Astrolabe", 
                     dependencies: ["RxSwift", "RxCocoa"], 
                     path: "./Sources/Core", 
                     exclude: [
                      "./Sources/Core/CollectionViewReusedPagerSource.swift",
                      "./Sources/Core/CollectionViewPagerSource.swift",                      
                      "./Sources/Core/ReusedPagerCollectionViewCell.swift",
                      "./Sources/Core/PagerCollectionViewCell.swift"
                     ])
    #else
      return .target(name: "Astrolabe", dependencies: ["RxSwift", "RxCocoa"], path: "./Sources/Core")
    #endif
  }
}

let package = Package(
    name: "Astrolabe",
    platforms: [
      .iOS(.v9), .tvOS(.v9)
    ],
    products: [
      .library(name: "Astrolabe", targets: ["Astrolabe"]),
      .library(name: "AstrolabeLoaders", targets: ["AstrolabeLoaders"])
    ],
    dependencies: [
      .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.1")),
      .package(url: "https://github.com/netcosports/Gnomon.git", .upToNextMajor(from: "5.1.1"))
    ],
    targets: [
      Target.astrolabe(),
      .target(name: "AstrolabeLoaders", dependencies: ["Astrolabe", "Gnomon", "RxSwift"], path: "./Sources/Loaders")
    ],
    swiftLanguageVersions: [.v5]
)
