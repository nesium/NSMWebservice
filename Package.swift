// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "NSMWebservice",
  platforms: [
    .iOS(.v11)
  ],
  products: [
    .library(name: "NSMWebservice", targets: ["NSMWebservice"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMinor(from: "4.4.2"))
  ],
  targets: [
    .target(name: "NSMWebservice", dependencies: ["RxSwift"])
  ]
)
