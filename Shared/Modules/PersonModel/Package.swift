// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersonModel",
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "PersonModel",
            targets: ["PersonModel"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(name: "TypePreservingCodingAdapter",
                 url: "https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git",
                 .upToNextMajor(from: "1.0.0")),
        .package(path: "../AppFoundation"),
        .package(path: "../HumanLifeModel"),
        .package(path: "../UnemployementModel"),
        .package(path: "../RetirementModel"),
        .package(path: "../NamedValue"),
        .package(path: "../ModelEnvironment"),
        .package(path: "../DateBoundary"),
        .package(path: "../Persistence")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "PersonModel",
            dependencies: [
                .product(name: "TypePreservingCodingAdapter", package: "TypePreservingCodingAdapter"),
                "AppFoundation",
                "HumanLifeModel",
                "UnemployementModel",
                "RetirementModel",
                "NamedValue",
                "ModelEnvironment",
                "DateBoundary",
                "Persistence"
            ]
        ),
        .testTarget(
            name: "PersonModelTests",
            dependencies: ["PersonModel"])
    ]
)
