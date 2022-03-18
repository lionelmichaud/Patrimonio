// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SocialAccounts",
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SocialAccounts",
            targets: ["SocialAccounts"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/JohnSundell/Files.git",
                 .upToNextMajor(from: "4.2.0")),
        .package(path: "../AppFoundation"),
        .package(path: "../Statistics"),
        .package(path: "../ModelEnvironment"),
        .package(path: "../Succession"),
        .package(path: "../LifeExpense"),
        .package(path: "../PatrimoineModel"),
        .package(path: "../FamilyModel"),
        .package(path: "../BalanceSheet"),
        .package(path: "../CashFlow"),
        .package(path: "../SimulationLogger"),
        .package(path: "../Kpi")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SocialAccounts",
            dependencies: [
                .product(name: "Files", package: "Files"),
                "AppFoundation",
                "Statistics",
                "ModelEnvironment",
                "Succession",
                "LifeExpense",
                "PatrimoineModel",
                "FamilyModel",
                "BalanceSheet",
                "CashFlow",
                "SimulationLogger",
                "Kpi"
            ]
        ),
        .testTarget(
            name: "SocialAccountsTests",
            dependencies: ["SocialAccounts"])
    ]
)
