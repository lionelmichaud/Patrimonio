// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SimulationAndVisitors",
    platforms: [.macOS(.v11), .iOS(.v14)], // Our minimum deployment target is 12
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "SimulationAndVisitors", targets: ["SimulationAndVisitors"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/JohnSundell/Files.git",
                 .upToNextMajor(from: "4.2.0")),
        .package(path: "../Stateful"),
        .package(path: "../Statistics"),
        .package(path: "../AppFoundation"),
        .package(path: "../EconomyModel"),
        .package(path: "../SocioEconomyModel"),
        .package(path: "../HumanLifeModel"),
        .package(path: "../ModelEnvironment"),
        .package(path: "../FamilyModel"),
        .package(path: "../PersonModel"),
        .package(path: "../PatrimoineModel"),
        .package(path: "../Succession"),
        .package(path: "../LifeExpense"),
        .package(path: "../BalanceSheet"),
        .package(path: "../CashFlow"),
        .package(path: "../SocialAccounts"),
        .package(path: "../Persistence"),
        .package(path: "../Persistable"),
        .package(path: "../SimulationLogger"),
        .package(path: "../Kpi")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SimulationAndVisitors",
            dependencies: [
                .product(name: "Files", package: "Files"),
                "Stateful",
                "Statistics",
                "AppFoundation",
                "EconomyModel",
                "SocioEconomyModel",
                "HumanLifeModel",
                "ModelEnvironment",
                "FamilyModel",
                "PersonModel",
                "PatrimoineModel",
                "Succession",
                "LifeExpense",
                "BalanceSheet",
                "CashFlow",
                "SocialAccounts",
                "Persistence",
                "Persistable",
                "SimulationLogger",
                "Kpi"
            ]
        ),
        .testTarget(
            name: "SimulationAndVisitorsTests",
            dependencies: ["SimulationAndVisitors"])
    ]
)
