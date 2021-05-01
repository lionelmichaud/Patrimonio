// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FiscalModel",
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FiscalModel",
            targets: ["FiscalModel"])
    ],
    dependencies:
        [
            // Dependencies declare other packages that this package depends on.
            // Using 'path', we can depend on a local package that's
            // located at a given path relative to our package's folder:
            .package(path: "../AppFoundation"),
                .package(url: "https://github.com/apple/swift-numerics.git", from: "0.0.8")
        ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FiscalModel",
            dependencies:
                [
                    "AppFoundation"
                ]
        ),
        .testTarget(
            name: "FiscalModelTests",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                "FiscalModel"
            ],
            resources: [
                .process("Resources") // We will store out assets here
            ]
        )
    ]
)
