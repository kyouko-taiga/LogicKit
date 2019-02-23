// swift-tools-version:4.2

import PackageDescription

let package = Package(
  name: "LogicKit",
  products: [
    .library(name: "LogicKit", type: .static, targets: ["LogicKit", "LogicKitBuiltins"]),
  ],
  targets: [
    .target(name: "LogicKit"),
    .target(name: "LogicKitBuiltins", dependencies: ["LogicKit"]),
    .testTarget(name: "LogicKitTests", dependencies: ["LogicKit"]),
    .testTarget(name: "LogicKitBuiltinsTests", dependencies: ["LogicKitBuiltins"]),
  ]
)
