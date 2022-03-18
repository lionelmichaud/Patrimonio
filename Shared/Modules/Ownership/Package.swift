// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Ownership",
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Ownership",
            targets: ["Ownership"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-numerics.git", from: "0.0.8"),
        .package(path: "../NamedValue"),
        .package(path: "../AppFoundation"),
        .package(path: "../FiscalModel")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Ownership",
            dependencies: [
                .product(name: "Numerics", package: "swift-numerics"),
                "AppFoundation",
                "NamedValue",
                "FiscalModel"
            ]),
        .testTarget(
            name: "OwnershipTests",
            dependencies: [
                "Ownership"
            ],
            resources: [
                .process("Resources") // We will store out assets here
            ]
        )
    ]
)
