//
//  EconomyModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import EconomyModel
//import AppFoundation

class EconomyModelTests: XCTestCase {
    
    static var economy: Economy!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        EconomyModelTests.economy = Economy(fromBundle : Bundle.module)
    }
    
    // MARK: Tests

    func test_loading_from_module_bundle() throws {
        XCTAssertNoThrow(Economy.Model(fromFile   : "EconomyModelConfig.json",
                                       fromBundle : Bundle.module),
                         "Failed to read model from Main Bundle \(String(describing: Bundle.module.resourcePath))")
    }
    
    func test_saving_to_module_bundle() throws {
        EconomyModelTests.economy.saveAsJSON(toBundle: Bundle.module)
    }
    
    func test_generation_aleatoire_outOfBounds() {
        XCTAssertThrowsError(try EconomyModelTests.economy.model?.nextRun(
                                simulateVolatility : false,
                                firstYear          : 2030,
                                lastYear           : 2029)) { error in
            XCTAssertEqual(error as! Economy.ModelError, Economy.ModelError.outOfBounds)
        }
        
        var dico = Economy.DictionaryOfRandomVariable()
        dico[.inflation]   = 0.0
        dico[.securedRate] = 0.0
        dico[.stockRate]   = 0.0
        XCTAssertThrowsError(try EconomyModelTests.economy.model?.setRandomValue(
                                to                 : dico,
                                simulateVolatility : false,
                                firstYear          : 2030,
                                lastYear           : 2029)) { error in
            XCTAssertEqual(error as! Economy.ModelError, Economy.ModelError.outOfBounds)
        }
    }
    
    func test_generation_aleatoire() throws {
        let firstYear = 2020
        let lastYear  = 2030
        
        XCTAssertNoThrow(try EconomyModelTests.economy.model?.nextRun(
                            simulateVolatility : false,
                            firstYear          : firstYear,
                            lastYear           : lastYear))
        
        // random & simulateVolatility = false
        var dico = try EconomyModelTests.economy.model?.nextRun(
            simulateVolatility : false,
            firstYear          : firstYear,
            lastYear           : lastYear)
        XCTAssertNotNil(dico)
        XCTAssertNotNil(dico?[.inflation])
        XCTAssertNotNil(dico?[.securedRate])
        XCTAssertNotNil(dico?[.stockRate])
        
        var dico2 = EconomyModelTests.economy.model?.currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(dico2?[.inflation])
        XCTAssertNotNil(dico2?[.securedRate])
        XCTAssertNotNil(dico2?[.stockRate])
        XCTAssertEqual(dico?[.inflation], dico2?[.inflation])
        XCTAssertEqual(dico?[.securedRate], dico2?[.securedRate])
        XCTAssertEqual(dico?[.stockRate], dico2?[.stockRate])

        XCTAssertEqual(EconomyModelTests.economy.model?.firstYearSampled, firstYear)
        XCTAssertEqual(EconomyModelTests.economy.model?.securedRateSamples.count, 0)
        XCTAssertEqual(EconomyModelTests.economy.model?.stockRateSamples.count, 0)
        
        // random & simulateVolatility = true
        dico = try EconomyModelTests.economy.model?.nextRun(
            simulateVolatility : true,
            firstYear          : firstYear,
            lastYear           : lastYear)
        XCTAssertNotNil(dico)
        XCTAssertNotNil(dico?[.inflation])
        XCTAssertNotNil(dico?[.securedRate])
        XCTAssertNotNil(dico?[.stockRate])
        
        dico2 = EconomyModelTests.economy.model?.currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(dico2?[.inflation])
        XCTAssertNotNil(dico2?[.securedRate])
        XCTAssertNotNil(dico2?[.stockRate])
        XCTAssertEqual(dico?[.inflation], dico2?[.inflation])
        XCTAssertEqual(dico?[.securedRate], dico2?[.securedRate])
        XCTAssertEqual(dico?[.stockRate], dico2?[.stockRate])
        
        XCTAssertEqual(EconomyModelTests.economy.model?.firstYearSampled, firstYear)
        XCTAssertEqual(EconomyModelTests.economy.model?.securedRateSamples.count, lastYear - firstYear + 1)
        XCTAssertEqual(EconomyModelTests.economy.model?.stockRateSamples.count, lastYear - firstYear + 1)
        
        dico = EconomyModelTests.economy.model?.currentRandomizersValues(withMode: .deterministic)
    }
    
    func test_reinit_rejeu() throws {
        let firstYear      = 2020
        let lastYear       = 2030
        var dico           = Economy.DictionaryOfRandomVariable()
        dico[.inflation]   = 0.0
        dico[.securedRate] = 0.0
        dico[.stockRate]   = 0.0

        // simulateVolatility = false
        try EconomyModelTests.economy.model?.setRandomValue(
            to                 : dico,
            simulateVolatility : false,
            firstYear          : firstYear,
            lastYear           : lastYear)
        XCTAssertEqual(EconomyModelTests.economy.model?.firstYearSampled, firstYear)
        XCTAssertEqual(EconomyModelTests.economy.model?.securedRateSamples.count, 0)
        XCTAssertEqual(EconomyModelTests.economy.model?.stockRateSamples.count, 0)
        
        var dico2 = EconomyModelTests.economy.model?.currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(dico2?[.inflation])
        XCTAssertNotNil(dico2?[.securedRate])
        XCTAssertNotNil(dico2?[.stockRate])
        XCTAssertEqual(dico[.inflation], dico2?[.inflation])
        XCTAssertEqual(dico[.securedRate], dico2?[.securedRate])
        XCTAssertEqual(dico[.stockRate], dico2?[.stockRate])

        // simulateVolatility = true
        try EconomyModelTests.economy.model?.setRandomValue(
            to                 : dico,
            simulateVolatility : true,
            firstYear          : firstYear,
            lastYear           : lastYear)
        XCTAssertEqual(EconomyModelTests.economy.model?.firstYearSampled, firstYear)
        XCTAssertEqual(EconomyModelTests.economy.model?.securedRateSamples.count, lastYear - firstYear + 1)
        XCTAssertEqual(EconomyModelTests.economy.model?.stockRateSamples.count, lastYear - firstYear + 1)
        
        dico2 = EconomyModelTests.economy.model?.currentRandomizersValues(withMode: .random)
        XCTAssertNotNil(dico2?[.inflation])
        XCTAssertNotNil(dico2?[.securedRate])
        XCTAssertNotNil(dico2?[.stockRate])
        XCTAssertEqual(dico[.inflation], dico2?[.inflation])
        XCTAssertEqual(dico[.securedRate], dico2?[.securedRate])
        XCTAssertEqual(dico[.stockRate], dico2?[.stockRate])
   }
    
    func test_inflation() {
        XCTAssertEqual(EconomyModelTests.economy.model?.inflation(withMode: .deterministic) , 1.5)
        XCTAssertEqual(EconomyModelTests.economy.inflation , 1.5)

        var economy = Economy(fromBundle : Bundle.module)
        economy.inflation = 2.0
        XCTAssertEqual(economy.inflation , 2.0)
        XCTAssertEqual(economy.persistenceSM.currentState , .modified)
    }
    
    func test_securedRate() {
        XCTAssertEqual(EconomyModelTests.economy.securedRate , 2.0)
        
        var economy = Economy(fromBundle : Bundle.module)
        economy.securedRate = 2.0
        XCTAssertEqual(economy.securedRate , 2.0)
        XCTAssertEqual(economy.persistenceSM.currentState , .modified)
    }
    
    func test_stockRate() {
        XCTAssertEqual(EconomyModelTests.economy.stockRate , 7.0)
        
        var economy = Economy(fromBundle : Bundle.module)
        economy.stockRate = 2.0
        XCTAssertEqual(economy.stockRate , 2.0)
        XCTAssertEqual(economy.persistenceSM.currentState , .modified)
    }
    
    func test_securedVolatility() {
        XCTAssertEqual(EconomyModelTests.economy.securedVolatility , 0.5)
        
        var economy = Economy(fromBundle : Bundle.module)
        economy.securedVolatility = 2.0
        XCTAssertEqual(economy.securedVolatility , 2.0)
        XCTAssertEqual(economy.persistenceSM.currentState , .modified)
    }
    
    func test_stockVolatility() {
        XCTAssertEqual(EconomyModelTests.economy.stockVolatility , 14.0)
        
        var economy = Economy(fromBundle : Bundle.module)
        economy.stockVolatility = 2.0
        XCTAssertEqual(economy.stockVolatility , 2.0)
        XCTAssertEqual(economy.persistenceSM.currentState , .modified)
    }
    
    func test_rates() throws {
        let determinist_rates = EconomyModelTests.economy.model!
            .rates(withMode: .deterministic)
        XCTAssertEqual(determinist_rates.securedRate, 2.0)
        XCTAssertEqual(determinist_rates.stockRate, 7.0)

        var dico           = Economy.DictionaryOfRandomVariable()
        dico[.inflation]   = 10.0
        dico[.securedRate] = 11.0
        dico[.stockRate]   = 12.0
        try EconomyModelTests.economy.model?.setRandomValue(
            to                 : dico,
            simulateVolatility : false,
            firstYear          : 2020,
            lastYear           : 2020)

        let random_rates = EconomyModelTests.economy.model!
            .rates(withMode: .random)
        XCTAssertEqual(random_rates.securedRate, 11.0)
        XCTAssertEqual(random_rates.stockRate, 12.0)
    }

    func test_rates_with_volatility() throws {
        // simulateVolatility : false
        var determinist_rates = EconomyModelTests.economy.model!
            .rates(in                 : 2025,
                   withMode           : .deterministic,
                   simulateVolatility : false)
        XCTAssertEqual(determinist_rates.securedRate, 2.0)
        XCTAssertEqual(determinist_rates.stockRate, 7.0)
        
        var dico           = Economy.DictionaryOfRandomVariable()
        dico[.inflation]   = 10.0
        dico[.securedRate] = 11.0
        dico[.stockRate]   = 12.0
        try EconomyModelTests.economy.model?.setRandomValue(
            to                 : dico,
            simulateVolatility : false,
            firstYear          : 2020,
            lastYear           : 2020)

        var random_rates = EconomyModelTests.economy.model!
            .rates(in                 : 2025,
                   withMode           : .random,
                   simulateVolatility : false)
        XCTAssertEqual(random_rates.securedRate, 11.0)
        XCTAssertEqual(random_rates.stockRate, 12.0)
        
        // simulateVolatility : true
        determinist_rates = EconomyModelTests.economy.model!
            .rates(in                 : 2025,
                   withMode           : .deterministic,
                   simulateVolatility : true)
        XCTAssertEqual(determinist_rates.securedRate, 2.0)
        XCTAssertEqual(determinist_rates.stockRate, 7.0)
        
        try EconomyModelTests.economy.model!.nextRun(
            simulateVolatility : true,
            firstYear          : 2020,
            lastYear           : 2025)
        random_rates = EconomyModelTests.economy.model!
            .rates(in                 : 2025,
                   withMode           : .random,
                   simulateVolatility : true)
        XCTAssertNotEqual(random_rates.securedRate, 0.0)
        XCTAssertNotEqual(random_rates.stockRate, 0.0)
    }
    
    func test_state_machine() {
        var economy = Economy(fromBundle : Bundle.module)
        
        XCTAssertFalse(economy.isModified)
        
        economy.inflation = 2.0
        XCTAssertTrue(economy.isModified)
        economy.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(economy.isModified)
        
        economy.securedRate = 2.0
        XCTAssertTrue(economy.isModified)
        economy.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(economy.isModified)
        
        economy.stockRate = 2.0
        XCTAssertTrue(economy.isModified)
        economy.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(economy.isModified)
        
        economy.securedVolatility = 2.0
        XCTAssertTrue(economy.isModified)
        economy.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(economy.isModified)
        
        economy.stockVolatility = 2.0
        XCTAssertTrue(economy.isModified)
        economy.saveAsJSON(toBundle: Bundle.module)
        XCTAssertFalse(economy.isModified)
    }
}
