// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SwiftModifiedDietz",
    platforms: [.macOS(.v10_12)], // needed for DateInterval support
    products: [
        .library(
            name: "ModifiedDietz",
            targets: ["ModifiedDietz"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ModifiedDietz",
            dependencies: [],
            path: "Sources"),
        .testTarget(
            name: "ModifiedDietzTests",
            dependencies: ["ModifiedDietz"],
            path: "Tests"),
    ]
)
