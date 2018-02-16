// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "NSMWebservice",
  products: [
    .library(name: "NSMWebservice", type: .dynamic, targets: ["NSMWebservice"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "4.1.2"), 
    .package(url: "https://github.com/pointfreeco/swift-snapshot-testing.git", .revision("e14c1a3f423196c443fef25f5d306bc9106cd557"))
  ],
  targets: [
    .target(name: "NSMWebservice", path: "NSMWebservice" )
  ]
)