// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Statistics",
    //defaultLocalization: "fr", // This allows for localization
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products:
        [
            // Products define the executables and libraries a package produces, and make them visible to other packages.
            .library(
                name: "Statistics",
                type: .static, // This is a static library
                targets: ["Statistics"])
        ],
    dependencies:
        [
            // Dependencies declare other packages that this package depends on.
            .package(url: "https://github.com/evgenyneu/SigmaSwiftStatistics.git", .upToNextMajor(from: "9.0.2")),
            .package(url: "https://github.com/apple/swift-numerics.git", from: "0.0.8"),
            // Using 'path', we can depend on a local package that's
            // located at a given path relative to our package's folder:
            .package(path: "../AppFoundation")
        ],
    targets:
        [
            // Targets are the basic building blocks of a package. A target can define a module or a test suite.
            // Targets can depend on other targets in this package, and on products in packages this package depends on.
            .target(
                name: "Statistics",
                dependencies:
                    [
                        .product(name: "Numerics", package: "swift-numerics"),
                        .product(name: "SigmaSwiftStatistics", package: "SigmaSwiftStatistics"),
                        "AppFoundation"
                    ],
                path: "Sources"),
            .testTarget(
                name: "StatisticsTests",
                dependencies: [
                    "Statistics"
                ])
        ]
)

//dependency 'Numerics' in target 'Statistics' requires explicit declaration; reference the package in the target dependency with '.product(name: "Numerics", package: "swift-numerics")'
