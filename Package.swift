// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "LogicKit",
    products: [
        .library(name: "LogicKit", type: .static, targets: ["LogicKit"]),
        .executable(name: "lki", targets: ["lki"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rxwei/Parsey.git", .revision("32f653044f95c880cd0cce929cfef29efb07ee5b")),
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
