//
//  SCPItests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 10/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import Statistics
import EconomyModel
import FiscalModel
@testable import AssetsModel

class SCPItests: XCTestCase {

    struct InflationProvider: InflationProviderP {
        func inflation(withMode simulationMode: SimulationModeEnum) -> Double {
            switch simulationMode {
                case .deterministic:
                    return 2.5
                case .random:
                    return 5.0
            }
        }
    }

    static var scpi: SCPI!
    static var inflationProvider = InflationProvider()

    func isApproximatelyEqual(_ x: Double, _ y: Double) -> Bool {
        if x == 0 {
            return abs((x-y)) < 0.0001
        } else {
            return abs((x-y)) / x < 0.0001
        }
    }
    
    // MARK: Helpers

    override class func setUp() {
        super.setUp()
        SCPItests.scpi = SCPI(fromFile             : SCPI.defaultFileName,
                              fromBundle           : Bundle.module,
                              dateDecodingStrategy : .iso8601,
                              keyDecodingStrategy  : .useDefaultKeys)
        SCPI.setSimulationMode(to: .deterministic)
        SCPI.setInflationProvider(SCPItests.inflationProvider)
        SCPI.setFiscalModelProvider(
            Fiscal.Model(fromFile   : "FiscalModelConfig.json",
                         fromBundle : Bundle.module)
                .initialized())
    }

    // MARK: Tests

    func test_description() {
        print("Test de SCPI.description")
        
        let str: String =
            String(describing: SCPItests.scpi!)
            .withPrefixedSplittedLines("  ")
        print(str)
    }
    
    func test_value() {
        var currentValue = SCPItests.scpi.value(atEndOf: 2020)
        XCTAssertTrue(isApproximatelyEqual((1000 * 0.9)*(1.1), currentValue))

        currentValue = SCPItests.scpi.value(atEndOf: 2022)
        XCTAssertTrue(isApproximatelyEqual((1000 * 0.9)*pow(1.1,3), currentValue))

        currentValue = SCPItests.scpi.value(atEndOf: 2023)
        XCTAssertEqual(0, currentValue)
    }

    func test_revenue() {
        // deterministic
        SCPI.setSimulationMode(to: .deterministic)
        var revenue = SCPItests.scpi.yearlyRevenue(during: 2020)
        XCTAssertEqual(1000.0 * (3.56 - 2.5) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2022)
        XCTAssertEqual(1000.0 * (3.56 - 2.5) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2023)
        XCTAssertEqual(0.0, revenue.revenue)
        
        // random
        SCPI.setSimulationMode(to: .random)
        revenue = SCPItests.scpi.yearlyRevenue(during: 2020)
        XCTAssertEqual(1000.0 * (3.56 - 5.0) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2022)
        XCTAssertEqual(1000.0 * (3.56 - 5.0) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2023)
        XCTAssertEqual(0.0, revenue.revenue)
    }

    func test_is_owned() {
        XCTAssertFalse(SCPItests.scpi.isOwned(during: 2018))
        XCTAssertTrue(SCPItests.scpi.isOwned(during: 2019))
        XCTAssertFalse(SCPItests.scpi.isOwned(during: 2023))
    }

    func test_liquidatedValueIRPP() {
        var venteIRPP = SCPItests.scpi.liquidatedValueIRPP(2021)
        XCTAssertEqual(0, venteIRPP.revenue)

        venteIRPP = SCPItests.scpi.liquidatedValueIRPP(2022)
        let venteTherory = (1000 * 0.9) * pow(1.1, 3)
        XCTAssertEqual(venteTherory.rounded(), venteIRPP.revenue.rounded())
        XCTAssertEqual((venteTherory-1000).rounded(), venteIRPP.capitalGain.rounded())
        XCTAssertEqual(venteIRPP.revenue-venteIRPP.irpp-venteIRPP.socialTaxes,
                       venteIRPP.netRevenue)

        venteIRPP = SCPItests.scpi.liquidatedValueIRPP(2023)
        XCTAssertEqual(0, venteIRPP.revenue)
    }

    func test_liquidatedValueIS() {
        var venteIS = SCPItests.scpi.liquidatedValueIS(2021)
        XCTAssertEqual(0, venteIS.revenue)

        venteIS = SCPItests.scpi.liquidatedValueIS(2022)
        let venteTherory = (1000 * 0.9) * pow(1.1, 3)
        XCTAssertEqual(venteTherory.rounded(), venteIS.revenue.rounded())
        XCTAssertEqual((venteTherory-1000).rounded(), venteIS.capitalGain.rounded())
        XCTAssertEqual(venteIS.revenue-venteIS.IS,
                       venteIS.netRevenue)

        venteIS = SCPItests.scpi.liquidatedValueIS(2023)
        XCTAssertEqual(0, venteIS.revenue)
    }

}
