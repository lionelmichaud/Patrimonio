//
//  OwnableTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 08/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import FiscalModel
import AppFoundation
@testable import Ownership

class OwnableTests: XCTestCase {
    
    // MARK: - Helpers
    
    struct OwnableItem: OwnableP {
        var ownership: Ownership = Ownership()
        
        var name: String
        
        func value(atEndOf year: Int) -> Double {
            Double(year)
        }
        
        func print() {
            Swift.print("Printed")
        }
    }
    
    static func ageOf(_ name: String, _ year: Int) -> Int {
        switch name {
            case "Owner1 de 65 ans en 2020":
                return 65 + (year - 2020)
            case "Owner2 de 55 ans en 2020":
                return 55 + (year - 2020)
            default:
                return 85 + (year - 2020)
        }
    }
    
    static var ownableItem            = OwnableItem(name: "default")
    static var ownableItemDemembre    = OwnableItem(name: "démembré")
    static var ownableItemNonDemembre = OwnableItem(name: "non démembré")
    
    override class func setUp() {
        super.setUp()
        let demembrementModel = DemembrementModel.Model(fromFile   : DemembrementModel.Model.defaultFileName,
                                                        fromBundle : Bundle.module)
        let demembrement = DemembrementModel(model: demembrementModel)
        
        Ownership.setDemembrementProviderP(demembrement)
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        OwnableTests.ownableItem.ownership = Ownership(ageOf: OwnableTests.ageOf)
        
        // Démembré: un seul usufruitier + 2 nupropriétaires
        OwnableTests.ownableItemDemembre.ownership = Ownership(ageOf: OwnableTests.ageOf)
        OwnableTests.ownableItemDemembre.ownership.isDismembered  = true
        OwnableTests.ownableItemDemembre.ownership.usufructOwners = [Owner(name: "Usufruitier", fraction : 100)]
        OwnableTests.ownableItemDemembre.ownership.bareOwners     = [Owner(name: "Nupropriétaire 1", fraction : 40),
                                                                     Owner(name: "Nupropriétaire 2", fraction : 60)]
        
        // Démembré: un seul usufruitier + 2 nupropriétaires
        OwnableTests.ownableItemNonDemembre.ownership = Ownership(ageOf: OwnableTests.ageOf)
        OwnableTests.ownableItemNonDemembre.ownership.isDismembered = false
        OwnableTests.ownableItemNonDemembre.ownership.fullOwners = [Owner(name: "Plein propriétaire", fraction : 100)]
    }
    
    // MARK: - Tests
    
    func test_owned_value() throws {
        // cas .legalSuccession d'un Nu-propriétaire
        var value = OwnableTests.ownableItemDemembre.ownership
            .ownedValue(by                : "Nupropriétaire 1",
                        ofValue           : OwnableTests.ownableItemDemembre.value(atEndOf: 2020),
                        atEndOf           : 2020,
                        evaluationContext : .legalSuccession)
        var ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                : "Nupropriétaire 1",
                        atEndOf           : 2020,
                        evaluationContext : .legalSuccession)
        
        XCTAssertEqual(value, ownedValue)
        
        // cas .legalSuccession d'un Usufruitier
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                : "Usufruitier",
                        atEndOf           : 2020,
                        evaluationContext : .legalSuccession)
        
        XCTAssertEqual(0, ownedValue)
        
        // cas .lifeInsuranceSuccession d'un Usufruitier
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                : "Usufruitier",
                        atEndOf           : 2020,
                        evaluationContext : .lifeInsuranceSuccession)
        
        XCTAssertEqual(0, ownedValue)
        
        // cas .patrimoine, .ifi, .isf d'un Usufruitier
        value = OwnableTests.ownableItemDemembre.ownership
            .ownedValue(by                : "Usufruitier",
                        ofValue           : OwnableTests.ownableItemDemembre.value(atEndOf: 2020),
                        atEndOf           : 2020,
                        evaluationContext : .patrimoine)
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                : "Usufruitier",
                        atEndOf           : 2020,
                        evaluationContext : .patrimoine)
        
        XCTAssertEqual(value, ownedValue)
        
        value = OwnableTests.ownableItemDemembre.ownership
            .ownedValue(by                : "Usufruitier",
                        ofValue           : OwnableTests.ownableItemDemembre.value(atEndOf: 2020),
                        atEndOf           : 2020,
                        evaluationContext : .ifi)
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                : "Usufruitier",
                        atEndOf           : 2020,
                        evaluationContext : .ifi)
        
        XCTAssertEqual(value, ownedValue)
        
        value = OwnableTests.ownableItemDemembre.ownership
            .ownedValue(by               : "Usufruitier",
                        ofValue          : OwnableTests.ownableItemDemembre.value(atEndOf: 2020),
                        atEndOf          : 2020,
                        evaluationContext : .isf)
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                : "Usufruitier",
                        atEndOf           : 2020,
                        evaluationContext : .isf)
        
        XCTAssertEqual(value, ownedValue)
    }
    
    func test_owned_values_demembre() throws {
        var ownedValues = OwnableTests.ownableItemDemembre
            .ownedValues(atEndOf           : 2020,
                         evaluationContext : .legalSuccession)
        
        XCTAssertNil(ownedValues["Plein propriétaire"])
        XCTAssertNotNil(ownedValues["Usufruitier"])
        XCTAssertNotNil(ownedValues["Nupropriétaire 1"])
        XCTAssertNotNil(ownedValues["Nupropriétaire 2"])
        
        ownedValues = OwnableTests.ownableItemDemembre
            .ownedValues(ofValue           : 100.0,
                         atEndOf           : 2020,
                         evaluationContext : .legalSuccession)
        
        XCTAssertNil(ownedValues["Plein propriétaire"])
        XCTAssertNotNil(ownedValues["Usufruitier"])
        XCTAssertNotNil(ownedValues["Nupropriétaire 1"])
        XCTAssertNotNil(ownedValues["Nupropriétaire 2"])
    }
    
    func test_owned_values_non_demembre() throws {
        var ownedValues = OwnableTests.ownableItemNonDemembre
            .ownedValues(atEndOf           : 2020,
                         evaluationContext : .legalSuccession)
        
        XCTAssertNotNil(ownedValues["Plein propriétaire"])
        XCTAssertNil(ownedValues["Usufruitier"])
        XCTAssertNil(ownedValues["Nupropriétaire 1"])
        XCTAssertNil(ownedValues["Nupropriétaire 2"])

        ownedValues = OwnableTests.ownableItemNonDemembre
            .ownedValues(ofValue           : 100.0,
                         atEndOf           : 2020,
                         evaluationContext : .legalSuccession)
        
        XCTAssertNotNil(ownedValues["Plein propriétaire"])
        XCTAssertNil(ownedValues["Usufruitier"])
        XCTAssertNil(ownedValues["Nupropriétaire 1"])
        XCTAssertNil(ownedValues["Nupropriétaire 2"])
    }
    
    func test_satisfies_non_demembre() throws {
        XCTAssertTrue(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .all, for: "Plein propriétaire"))
        XCTAssertTrue(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .generatesRevenue, for: "Plein propriétaire"))
        XCTAssertTrue(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .sellable, for: "Plein propriétaire"))
        
        XCTAssertFalse(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .all, for: "Nupropriétaire 1"))
        XCTAssertFalse(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .all, for: "Nupropriétaire 2"))
        
        XCTAssertFalse(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .generatesRevenue, for: "Nupropriétaire 1"))
        XCTAssertFalse(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .generatesRevenue, for: "Nupropriétaire 2"))
        
        XCTAssertFalse(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .sellable, for: "Nupropriétaire 1"))
        XCTAssertFalse(OwnableTests.ownableItemNonDemembre
                        .satisfies(criteria: .sellable, for: "Nupropriétaire 2"))
    }

    func test_satisfies_demembre() throws {
        XCTAssertTrue(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .all, for: "Usufruitier"))
        XCTAssertTrue(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .generatesRevenue, for: "Usufruitier"))
        XCTAssertFalse(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .sellable, for: "Usufruitier"))
        
        XCTAssertTrue(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .all, for: "Nupropriétaire 1"))
        XCTAssertTrue(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .all, for: "Nupropriétaire 2"))
        XCTAssertFalse(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .generatesRevenue, for: "Nupropriétaire 1"))
        XCTAssertFalse(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .generatesRevenue, for: "Nupropriétaire 2"))
        XCTAssertFalse(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .sellable, for: "Nupropriétaire 1"))
        XCTAssertFalse(OwnableTests.ownableItemDemembre
                        .satisfies(criteria: .sellable, for: "Nupropriétaire 2"))
    }
    
    func test_ownedValue_withOwnershipNature() {
        var ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                  : "Usufruitier",
                        atEndOf             : 2020,
                        withOwnershipNature : .generatesRevenue,
                        evaluatedFraction   : .totalValue)
        let totalValue = OwnableTests.ownableItemNonDemembre
            .value(atEndOf: 2020).rounded()
        XCTAssertEqual(ownedValue, totalValue)
        
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                  : "Usufruitier",
                        atEndOf             : 2020,
                        withOwnershipNature : .generatesRevenue,
                        evaluatedFraction   : .ownedValue)
        let value = OwnableTests.ownableItemDemembre
            .ownedValue(by               : "Usufruitier",
                        atEndOf          : 2020,
                        evaluationContext: .patrimoine).rounded()
        XCTAssertEqual(ownedValue, value)
        
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                  : "Nupropriétaire 1",
                        atEndOf             : 2020,
                        withOwnershipNature : .generatesRevenue,
                        evaluatedFraction   : .totalValue)
        XCTAssertEqual(ownedValue, 0.0)
        ownedValue = OwnableTests.ownableItemDemembre
            .ownedValue(by                  : "Nupropriétaire 1",
                        atEndOf             : 2020,
                        withOwnershipNature : .generatesRevenue,
                        evaluatedFraction   : .ownedValue)
        XCTAssertEqual(ownedValue, 0.0)
    }
}
