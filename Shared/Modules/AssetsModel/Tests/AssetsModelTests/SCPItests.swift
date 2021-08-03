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

    struct InflationProvider: EconomyModelProviderP {
        func rates(in year            : Int,
                   withMode mode      : SimulationModeEnum,
                   simulateVolatility : Bool) -> (securedRate : Double, stockRate : Double) {
            (securedRate: Double(year) + 5.0, stockRate: Double(year) + 10.0)
        }
        
        func rates(withMode mode: SimulationModeEnum) -> (securedRate: Double, stockRate: Double) {
            (securedRate: 5.0, stockRate: 10.0)
        }
        
        func inflation(withMode simulationMode: SimulationModeEnum) -> Double {
            2.5
        }
    }

    static var scpi: SCPI!
    static var inflationProvider = InflationProvider()

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
        XCTAssertEqual(1000 * 0.9, currentValue)

        currentValue = SCPItests.scpi.value(atEndOf: 2022)
        XCTAssertEqual(1000 * 0.9, currentValue)

        currentValue = SCPItests.scpi.value(atEndOf: 2023)
        XCTAssertEqual(0, currentValue)
    }

    func test_revenue() {
        var revenue = SCPItests.scpi.yearlyRevenue(during: 2020)
        XCTAssertEqual(1000.0 * (3.56 - 10.0) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2022)
        XCTAssertEqual(1000.0 * (3.56 - 10.0) / 100.0, revenue.revenue)

        revenue = SCPItests.scpi.yearlyRevenue(during: 2023)
        XCTAssertEqual(0.0, revenue.revenue)
    }

    func test_is_owned() {
        XCTAssertFalse(SCPItests.scpi.isOwned(during: 2018))
        XCTAssertTrue(SCPItests.scpi.isOwned(during: 2019))
        XCTAssertFalse(SCPItests.scpi.isOwned(during: 2023))
    }

    func test_liquidatedValue() {
        var vente = SCPItests.scpi.liquidatedValueIS(2021)
        XCTAssertEqual(0, vente.revenue)

        let venteIRPP = SCPItests.scpi.liquidatedValueIRPP(2022)
        XCTAssertEqual(1000 * 0.9, venteIRPP.revenue)
        XCTAssertEqual(-1000 * 0.1, venteIRPP.capitalGain)
        XCTAssertEqual(0, venteIRPP.socialTaxes)
        XCTAssertEqual(0, venteIRPP.irpp)
        XCTAssertEqual(venteIRPP.revenue, venteIRPP.netRevenue)

        vente = SCPItests.scpi.liquidatedValueIS(2023)
        XCTAssertEqual(0, vente.revenue)
    }
}
