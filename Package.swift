// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "LogicKit",
    products: [
        .library(name: "LogicKit", type: .static, targets: ["LogicKit"]),
        .executable(name: "lki", targets: ["lki"]),
    ],
    dependencies: [
        .package(url: "https://github.com/kyouko-taiga/Parsey", .branch("master")),
    ],
    targets: [
        .target(name: "LogicKit"),
        .target(name: "LogicKitParser", dependencies: ["LogicKit", "Parsey"]),
        .target(name: "lki", dependencies: ["LogicKit", "LogicKitParser", "linenoise"]),
        .target(name: "linenoise"),

        .testTarget(name: "LogicKitTests", dependencies: ["LogicKit"]),
        .testTarget(name: "LogicKitParserTests", dependencies: ["LogicKit", "LogicKitParser"]),
    ]
)
