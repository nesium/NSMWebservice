// swift-tools-version:4.0

import PackageDescription

let package = Package(
  name: "NSMWebservice",
  products: [
    .library(name: "NSMWebservice", type: .dynamic, targets: ["NSMWebservice"]),
  ],
  dependencies: [
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "2.8.0"),
    .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "4.1.2")
  ],
  targets: [
    .target(name: "NSMWebservice", path: "NSMWebservice" )
  ]
)