// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CashFlow",
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "CashFlow",
            targets: ["CashFlow"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(path: "../AppFoundation"),
        .package(path: "../Statistics"),
        .package(path: "../NamedValue"),
        .package(path: "../FiscalModel"),
        .package(path: "../ModelEnvironment"),
        .package(path: "../LifeExpense"),
        .package(path: "../Ownership"),
        .package(path: "../PatrimoineModel"),
        .package(path: "../PersonModel"),
        .package(path: "../FamilyModel"),
        .package(path: "../SuccessionManager"),
        .package(path: "../Succession"),
        .package(path: "../Persistence"),
        .package(path: "../SimulationLogger"),
        .package(path: "../Liabilities")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CashFlow",
            dependencies: [
                "AppFoundation",
                "Statistics",
                "NamedValue",
                "FiscalModel",
                "ModelEnvironment",
                "LifeExpense",
                "Ownership",
                "PatrimoineModel",
                "PersonModel",
                "FamilyModel",
                "Succession",
                "SuccessionManager",
                "Persistence",
                "SimulationLogger",
                "Liabilities"
            ]
        ),
        .testTarget(
            name: "CashFlowTests",
            dependencies: ["CashFlow"])
    ]
)
