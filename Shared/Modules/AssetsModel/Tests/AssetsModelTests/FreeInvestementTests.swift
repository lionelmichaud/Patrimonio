//
//  FreeInvestementTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 12/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import Statistics
import EconomyModel
import FiscalModel
import Ownership
@testable import AssetsModel

class FreeInvestementTests: XCTestCase {
    typealias Tests = FreeInvestementTests
    
    struct EconomyModelProvider: EconomyModelProviderP {
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

    static var economyModelProvider  = EconomyModelProvider()
    static var fi                    : FreeInvestement!
    static var inflation             : Double = 0.0
    static var rates                 = (securedRate : 0.0, stockRate : 0.0)
    static var rates2021             = (securedRate : 0.0, stockRate : 0.0)
    static var averageRateTheory     : Double = 0.0
    static var averageRate2021Theory : Double = 0.0
    
    static var verbose = true

    override func setUp() {
        super.setUp()
        FreeInvestement.setSimulationMode(to: .deterministic)
        FreeInvestement.setEconomyModelProvider(FreeInvestementTests.economyModelProvider)
        FreeInvestement.setFiscalModelProvider(
            Fiscal.Model(fromFile   : "FiscalModelConfig.json",
                         fromBundle : Bundle.module)
                .initialized())
        
        FreeInvestementTests.fi = FreeInvestement(fromFile   : FreeInvestement.defaultFileName,
                                                  fromBundle : Bundle.module)
        FreeInvestementTests.fi.resetCurrentState()
        //print(FreeInvestementTests.fi!)
        
        FreeInvestementTests.inflation =
            FreeInvestementTests
            .economyModelProvider
            .inflation(withMode: .deterministic)
        
        FreeInvestementTests.rates =
            FreeInvestementTests
            .economyModelProvider
            .rates(withMode: .deterministic)
        FreeInvestementTests.averageRateTheory =
            (0.75 * FreeInvestementTests.rates.stockRate + 0.25 * FreeInvestementTests.rates.securedRate)
            - FreeInvestementTests.inflation
        
        FreeInvestementTests.rates2021 =
            FreeInvestementTests
            .economyModelProvider
            .rates(in: 2021, withMode: .deterministic, simulateVolatility: false)
        FreeInvestementTests.averageRate2021Theory =
            (0.75 * FreeInvestementTests.rates2021.stockRate + 0.25 * FreeInvestementTests.rates2021.securedRate)
            - FreeInvestementTests.inflation
    }
    
    func test_description() {
        print("Test de FreeInvestement.description")
        
        let str: String =
            String(describing: FreeInvestementTests.fi!)
            .withPrefixedSplittedLines("  ")
        print(str)
    }
    
    func test_averageInterestRate() {
        XCTAssertEqual(FreeInvestementTests.averageRateTheory, Tests.fi.averageInterestRateNetOfInflation)
        
        Tests.fi.interestRateType = .contractualRate(fixedRate: 2.5)
        XCTAssertEqual(2.5 - FreeInvestementTests.inflation, Tests.fi.averageInterestRateNetOfInflation)
    }
    
    func test_averageInterestRateNet() {
        Tests.fi.type = .lifeInsurance(periodicSocialTaxes : true,
                                 clause              : LifeInsuranceClause())
        XCTAssertGreaterThan(FreeInvestementTests.averageRateTheory, Tests.fi.averageInterestRateNetOfTaxesAndInflation)
        
        Tests.fi.type = .lifeInsurance(periodicSocialTaxes : false,
                                 clause              : LifeInsuranceClause())
        XCTAssertEqual(Tests.fi.averageInterestRateNetOfInflation, Tests.fi.averageInterestRateNet)
        
        Tests.fi.type = .pea
        XCTAssertEqual(Tests.fi.averageInterestRateNetOfInflation, Tests.fi.averageInterestRateNet)
        
        Tests.fi.type = .other
        XCTAssertEqual(Tests.fi.averageInterestRateNetOfInflation, Tests.fi.averageInterestRateNet)
    }
    
    func test_split() {
        let split = Tests.fi.split(removal: Tests.fi.currentState.value / 2.0)
        let expected = (investement : Tests.fi.currentState.investment / 2.0,
                        interest    : Tests.fi.currentState.interest / 2.0)

        XCTAssertEqual(expected.investement, split.investment)
        XCTAssertEqual(expected.interest, split.interest)
    }
    
    func test_value() {
        let value = Tests.fi.value(atEndOf: 2020)
        let expected = Tests.fi.currentState.value

        XCTAssertEqual(expected, value)
    }
    
    func test_deposit() {
        let OldValue = Tests.fi.value(atEndOf: 2020)
        let deposit = 100.0
        
        Tests.fi.deposit(deposit)

        XCTAssertEqual(OldValue + deposit, Tests.fi.value(atEndOf: 2020))
    }
    
    func test_capitalize() throws {
        let interest = Tests.fi.lastKnownState.value * FreeInvestementTests.averageRate2021Theory / 100.0

        XCTAssertThrowsError(try Tests.fi.capitalize(atEndOf: 2020)) { error in
            XCTAssertEqual(error as! FreeInvestementError, FreeInvestementError.IlegalOperation)
        }
        XCTAssertThrowsError(try Tests.fi.capitalize(atEndOf: 2022)) { error in
            XCTAssertEqual(error as! FreeInvestementError, FreeInvestementError.IlegalOperation)
        }
        
        try Tests.fi.capitalize(atEndOf: 2021)
        
        XCTAssertEqual(Tests.fi.lastKnownState.value + interest, Tests.fi.value(atEndOf: 2021))
    }
    
    func test_ownedValue() {
        let defunt   = "M. Lionel MICHAUD"
        let enfant1  = "Mme. Lou-Ann MICHAUD"
        let enfant2  = "M. Arthur MICHAUD"

        // lifeInsurance + legalSuccession
        var ownedValue = Tests.fi.ownedValue(by               : defunt,
                                       atEndOf          : 2020,
                                       evaluationContext : .legalSuccession)
        XCTAssertEqual(0, ownedValue)
        
        // lifeInsurance + patrimoine
        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                   atEndOf          : 2020,
                                   evaluationContext : .patrimoine)
        XCTAssertEqual(Tests.fi.value(atEndOf: 2020), ownedValue)

        // lifeInsurance + lifeInsuranceSuccession
        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                   atEndOf          : 2020,
                                   evaluationContext : .lifeInsuranceSuccession)
        XCTAssertEqual(Tests.fi.value(atEndOf: 2020), ownedValue)
        
        // lifeInsurance + lifeInsuranceTransmission
        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                   atEndOf          : 2020,
                                   evaluationContext : .lifeInsuranceTransmission)
        XCTAssertEqual(Tests.fi.value(atEndOf: 2020), ownedValue)
        
        // pea + legalSuccession / défunt = PP
        Tests.fi.type = .pea
        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                   atEndOf          : 2020,
                                   evaluationContext : .legalSuccession)
        XCTAssertEqual(Tests.fi.value(atEndOf: 2020), ownedValue)

        // pea + patrimoine
        Tests.fi.type = .pea
        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                   atEndOf          : 2020,
                                   evaluationContext : .patrimoine)
        XCTAssertEqual(Tests.fi.value(atEndOf: 2020), ownedValue)

        // pea + lifeInsuranceSuccession
        Tests.fi.type = .pea
        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                   atEndOf          : 2020,
                                   evaluationContext : .lifeInsuranceSuccession)
        XCTAssertEqual(0, ownedValue)

        // pea + legalSuccession / défunt = UF
        Tests.fi.type = .pea
        var ownership = Tests.fi.ownership
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: defunt, fraction: 100.0)]
        ownership.bareOwners = [Owner(name: enfant1, fraction: 40.0),
                                Owner(name: enfant2, fraction: 60.0)]
        Tests.fi.ownership = ownership

        ownedValue = Tests.fi.ownedValue(by               : defunt,
                                         atEndOf          : 2020,
                                         evaluationContext : .legalSuccession)
        XCTAssertEqual(0, ownedValue)
    }
    
    func test_withdrawLifeInsuranceCapitalDeces() {
        let defunt   = "M. Lionel MICHAUD"
        let enfant1  = "M. Arthur MICHAUD"
        let enfant2  = "Mme. Lou-Ann MICHAUD"
        
        var interestBefore   = Tests.fi.currentState.interest
        var investmentBefore = Tests.fi.currentState.investment
        
        // cas n°1
        Tests.fi.withdrawLifeInsuranceCapitalDeces(of: enfant1)
        
        XCTAssertEqual(interestBefore, Tests.fi.currentState.interest)
        XCTAssertEqual(investmentBefore, Tests.fi.currentState.investment)
        
        // cas n°2
        Tests.fi.withdrawLifeInsuranceCapitalDeces(of: defunt)
        
        XCTAssertEqual(0.0, Tests.fi.currentState.interest)
        XCTAssertEqual(0.0, Tests.fi.currentState.investment)
        
        // cas n°3
        FreeInvestementTests.fi = FreeInvestement(fromFile   : FreeInvestement.defaultFileName,
                                                  fromBundle : Bundle.module)
        FreeInvestementTests.fi.resetCurrentState()
        var ownership = Tests.fi.ownership
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: defunt,  fraction: 40),
                                Owner(name: enfant1, fraction: 35),
                                Owner(name: enfant2, fraction: 25)]
        Tests.fi.ownership = ownership

        interestBefore   = Tests.fi.currentState.interest
        investmentBefore = Tests.fi.currentState.investment
        
        Tests.fi.withdrawLifeInsuranceCapitalDeces(of: defunt)
        
        let expectedInterestAfter   = interestBefore * (1.0 - 40.0/100.0)
        let expectedInvestmentAfter = investmentBefore * (1.0 - 40.0/100.0)

        XCTAssertEqual(expectedInterestAfter, Tests.fi.currentState.interest)
        XCTAssertEqual(expectedInvestmentAfter, Tests.fi.currentState.investment)
    }
    
    func test_withdrawal() {
        let defunt   = "M. Lionel MICHAUD"
        let enfant1  = "M. Arthur MICHAUD"
        let removed = 50.0
        
        // Cas n°1: AV
        var withdrawal = Tests.fi.withdrawal(netAmount: 50.0,
                                             for: enfant1,
                                             verbose: Tests.verbose)
        
        XCTAssertEqual(withdrawal.revenue         , 0.0)
        XCTAssertEqual(withdrawal.interests       , 0.0)
        XCTAssertEqual(withdrawal.netInterests    , 0.0)
        XCTAssertEqual(withdrawal.taxableInterests, 0.0)
        XCTAssertEqual(withdrawal.socialTaxes     , 0.0)
        
        // Cas n°2: AV
        withdrawal = Tests.fi.withdrawal(netAmount: removed,
                                         for: defunt,
                                         verbose: Tests.verbose)
        
        XCTAssertEqual(withdrawal.revenue,          removed)
        XCTAssertEqual(withdrawal.interests,        removed * 10.0/100.0)
        XCTAssertEqual(withdrawal.netInterests,     removed * 10.0/100.0)
        XCTAssertEqual(withdrawal.taxableInterests, removed * 10.0/100.0)
        XCTAssertEqual(withdrawal.socialTaxes, 0.0)

        // cas n°3: AV
        FreeInvestementTests.fi = FreeInvestement(fromFile   : FreeInvestement.defaultFileName,
                                                  fromBundle : Bundle.module)
        FreeInvestementTests.fi.resetCurrentState()
        var ownership = Tests.fi.ownership
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: defunt,  fraction: 40),
                                Owner(name: enfant1, fraction: 60)]
        Tests.fi.ownership = ownership
        
        withdrawal = Tests.fi.withdrawal(netAmount: removed,
                                         for: defunt,
                                         verbose: Tests.verbose)
        
        XCTAssertEqual(withdrawal.revenue,          40.0)
        XCTAssertEqual(withdrawal.interests,        40.0 * 10.0/100.0)
        XCTAssertEqual(withdrawal.netInterests,     40.0 * 10.0/100.0)
        XCTAssertEqual(withdrawal.taxableInterests, 40.0 * 10.0/100.0)
        XCTAssertEqual(withdrawal.socialTaxes, 0.0)
        XCTAssertEqual(Tests.fi.ownership.fullOwners, [Owner(name: enfant1, fraction: 100)])
    }
}
