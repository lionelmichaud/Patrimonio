// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SuccessionManager",
    platforms: [.macOS(.v12), .iOS(.v15)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SuccessionManager",
            targets: ["SuccessionManager"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../FiscalModel"),
        .package(path: "../ModelEnvironment"),
        .package(path: "../Succession"),
        .package(path: "../NamedValue"),
        .package(path: "../Ownership"),
        .package(path: "../AssetsModel"),
        .package(path: "../Liabilities"),
        .package(path: "../PatrimoineModel"),
        .package(path: "../PersonModel"),
        .package(path: "../FamilyModel"),
        .package(path: "../SimulationLogger")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SuccessionManager",
            dependencies: [
                "FiscalModel",
                "ModelEnvironment",
                "Succession",
                "NamedValue",
                "Ownership",
                "AssetsModel",
                "Liabilities",
                "PatrimoineModel",
                "PersonModel",
                "FamilyModel",
                "SimulationLogger"
            ]
        ),
        .testTarget(
            name: "SuccessionManagerTests",
            dependencies: [
                "SuccessionManager"
            ],
            resources: [
                .process("Resources") // We will store out assets here
            ]
        )
    ]
)
