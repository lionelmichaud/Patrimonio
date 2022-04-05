// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FamilyModel",
    platforms: [.macOS(.v12), .iOS(.v15)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FamilyModel",
            targets: ["FamilyModel"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git",
                 //"TypePreservingCodingAdapter",
                 from: "1.0.0"),
        .package(path: "../AppFoundation"),
        .package(path: "../ModelEnvironment"),
        .package(path: "../Ownership"),
        .package(path: "../DateBoundary"),
        .package(path: "../LifeExpense"),
        .package(path: "../PersonModel"),
        .package(path: "../PatrimoineModel")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FamilyModel",
            dependencies: [
                .product(name: "TypePreservingCodingAdapter", package: "Type-Preserving-Coding-Adapter"),
                "AppFoundation",
                "ModelEnvironment",
                "Ownership",
                "DateBoundary",
                "LifeExpense",
                "PersonModel",
                "PatrimoineModel"
            ]
        ),
        .testTarget(
            name: "FamilyModelTests",
            dependencies: ["FamilyModel"])
    ]
)
