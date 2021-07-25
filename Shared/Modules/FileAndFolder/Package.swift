// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FileAndFolder",
    platforms: [.iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FileAndFolder",
            targets: ["FileAndFolder"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/JohnSundell/Files.git", .upToNextMajor(from: "4.2.0")),
        .package(path: "../AppFoundation")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FileAndFolder",
            dependencies:
                [
                    .product(name: "Files", package: "Files"),
                    "AppFoundation"
                ]),
        .testTarget(
            name: "FileAndFolderTests",
            dependencies: [
                "FileAndFolder",
                "AppFoundation"
            ])
    ]
)
