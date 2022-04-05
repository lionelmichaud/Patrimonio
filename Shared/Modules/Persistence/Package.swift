// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Persistence",
    platforms: [.macOS(.v12), .iOS(.v15)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Persistence",
            targets: ["Persistence"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/jessesquires/Foil.git", .upToNextMajor(from: "1.0.0")),
        .package(path: "../AppFoundation"),
        .package(path: "../Ownership"),
        .package(path: "../NamedValue"),
        .package(path: "../FileAndFolder")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Persistence",
            dependencies:
                [
                    .product(name: "Foil", package: "Foil"),
                    "AppFoundation",
                    "Ownership",
                    "NamedValue",
                    "FileAndFolder"
                ]),
        .testTarget(
            name: "PersistenceTests",
            dependencies: ["Persistence"]
        )
    ]
)
