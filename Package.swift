// swift-tools-version:5.0

import PackageDescription

extension Target {

  static func astrolabe() -> Target {
    #if os(tvOS)
      return .target(name: "Astrolabe", 
                     dependencies: ["RxSwift", "RxCocoa"], 
                     path: "./Sources",
                     exclude: [
                      "./Sources/Core/CollectionViewReusedPagerSource.swift",
                      "./Sources/Core/CollectionViewPagerSource.swift",                      
                      "./Sources/Core/ReusedPagerCollectionViewCell.swift",
                      "./Sources/Core/PagerCollectionViewCell.swift"
                     ],
                     linkerSettings: [
                      .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                     ])
    #else
      return .target(name: "Astrolabe",
                     dependencies: ["RxSwift", "RxCocoa"],
                     path: "./Sources",
                     linkerSettings: [
                      .linkedFramework("UIKit", .when(platforms: [.iOS, .tvOS])),
                     ])
    #endif
  }
}

let package = Package(
    name: "Astrolabe",
    platforms: [
      .iOS(.v9), .tvOS(.v9)
    ],
    products: [
      .library(name: "Astrolabe", targets: ["Astrolabe"])
    ],
    dependencies: [
      .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "6.0.0")),
      .package(url: "https://github.com/Quick/Nimble.git", .branch("main")),
      .package(url: "https://github.com/Quick/Quick.git", .branch("main"))
    ],
    targets: [
      .testTarget(
        name: "AstrolabeTests",
        dependencies: [
          "Astrolabe",
          "Nimble",
          "Quick"
        ]
      ),
      Target.astrolabe()
    ],
    swiftLanguageVersions: [.v5]
)
