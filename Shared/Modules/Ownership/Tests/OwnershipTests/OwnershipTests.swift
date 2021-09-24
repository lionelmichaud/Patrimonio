//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 24/09/2021.
//

import XCTest
import FiscalModel
import AppFoundation
@testable import Ownership

class OwnershipTests: XCTestCase {
    static var fullOwner1     : Owner!
    static var fullOwner2     : Owner!
    static var bareOwner1     : Owner!
    static var bareOwner2     : Owner!
    static var usufructOwner1 : Owner!
    static var usufructOwner2 : Owner!
    
    static var fullOwners     = Owners()
    static var bareOwners     = Owners()
    static var usufructOwners = Owners()
    
    static var ownership            = Ownership()
    static var ownershipDemembre    = Ownership()
    static var ownershipNonDemembre = Ownership()

    // MARK: - Helpers
    
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
    
    override class func setUp() {
        super.setUp()
        let demembrementModel = DemembrementModel.Model(fromFile   : DemembrementModel.Model.defaultFileName,
                                                        fromBundle : Bundle.module)
        let demembrement = DemembrementModel(model: demembrementModel)
        
        Ownership.setDemembrementProviderP(demembrement)
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        OwnershipTests.ownership = Ownership(ageOf: OwnableTests.ageOf)
        
        // Démembré: un seul usufruitier + 2 nupropriétaires
        OwnershipTests.ownershipDemembre = Ownership(ageOf: OwnableTests.ageOf)
        OwnershipTests.ownershipDemembre.isDismembered  = true
        OwnershipTests.ownershipDemembre.usufructOwners = [Owner(name: "Owner2 de 55 ans en 2020", fraction : 100)]
        OwnershipTests.ownershipDemembre.bareOwners     = [Owner(name: "Nupropriétaire 1", fraction : 40),
                                                           Owner(name: "Nupropriétaire 2", fraction : 60)]
        
        // Démembré: un seul usufruitier + 2 nupropriétaires
        OwnershipTests.ownershipNonDemembre = Ownership(ageOf: OwnableTests.ageOf)
        OwnershipTests.ownershipNonDemembre.isDismembered  = false
        OwnershipTests.ownershipNonDemembre.fullOwners = [Owner(name: "Owner1 de 65 ans en 2020", fraction : 100)]
    }
    
    // MARK: - Tests
    
    func test_isValid() {
        XCTAssertTrue(OwnershipTests.ownershipDemembre.isValid)
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.isValid)
    }
    
    func test_isNotValid() {
        OwnershipTests.ownershipDemembre.usufructOwners = [Owner(name: "Owner2 de 55 ans en 2020", fraction : 50)]
        XCTAssertFalse(OwnershipTests.ownershipDemembre.isValid)
        OwnershipTests.ownershipDemembre.usufructOwners = [Owner(name: "Owner2 de 55 ans en 2020", fraction : 100)]
        OwnershipTests.ownershipDemembre.bareOwners     = [Owner(name: "Nupropriétaire 1", fraction : 40),
                                                           Owner(name: "Nupropriétaire 2", fraction : 50)]
        XCTAssertFalse(OwnershipTests.ownershipDemembre.isValid)

        OwnershipTests.ownershipNonDemembre.fullOwners = [Owner(name: "Owner1 de 65 ans en 2020", fraction : 50)]
        XCTAssertFalse(OwnershipTests.ownershipNonDemembre.isValid)
    }
    
    func test_ownership_demembrement() throws {
        var (usufructValue, bareValue) : (Double, Double) = (0, 0)
        XCTAssertNoThrow((usufructValue, bareValue) =
                            try OwnershipTests.ownershipDemembre.demembrement(ofValue: 100, atEndOf: 2020))
        XCTAssertEqual(100.0, usufructValue + bareValue)
    }
    
    func test_demembrementPercentage() throws {
        var (usufructPercent, bareValuePercent) : (Double, Double) = (0, 0)
        XCTAssertNoThrow((usufructPercent, bareValuePercent) =
                            try OwnershipTests.ownershipDemembre.demembrementPercentage(atEndOf: 2020))
        XCTAssertEqual(100.0, usufructPercent + bareValuePercent)
    }
    
    func test_owner_ownedRevenue_not_dismembered() {
        var ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenue(by: "inconnu",
                                                                            ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 0)
        
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenue(by: "Owner1 de 65 ans en 2020",
                                                                        ofRevenue: 100)
        XCTAssertGreaterThan(ownedRevenue, 0)
    }
    
    func test_owner_ownedRevenue_dismembered() {
        var ownedRevenue = OwnershipTests.ownershipDemembre.ownedRevenue(by: "inconnu",
                                                                         ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 0)
        
        ownedRevenue = OwnershipTests.ownershipDemembre.ownedRevenue(by: "Owner2 de 55 ans en 2020",
                                                                     ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 100)
        ownedRevenue = OwnershipTests.ownershipDemembre.ownedRevenue(by: "Nupropriétaire 1",
                                                                     ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 0)
        
        ownedRevenue = OwnershipTests.ownershipDemembre.ownedRevenue(by: "Nupropriétaire 2",
                                                                     ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 0)
    }
    
    func test_owners_ownedRevenue_not_dismembered() {
        var ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenue(by: ["inconnu"],
                                                                            ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 0)
        
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenue(by: ["Owner1 de 65 ans en 2020"],
                                                                        ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 100)

        OwnershipTests.ownershipNonDemembre.fullOwners = [Owner(name: "Owner1 de 65 ans en 2020", fraction : 40),
                                                          Owner(name: "Owner1 de 55 ans en 2020", fraction : 50),
                                                          Owner(name: "truc", fraction : 10)]
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenue(by: ["Owner1 de 65 ans en 2020"],
                                                                        ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 40)
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenue(by: ["Owner1 de 65 ans en 2020",
                                                                             "Owner1 de 55 ans en 2020"],
                                                                        ofRevenue: 100)
        XCTAssertEqual(ownedRevenue, 90)
    }
    
    func test_owners_ownedRevenueFraction_not_dismembered() {
        var ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenueFraction(by: ["inconnu"])
        XCTAssertEqual(ownedRevenue, 0)
        
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenueFraction(by: ["Owner1 de 65 ans en 2020"])
        XCTAssertEqual(ownedRevenue, 100)
        
        OwnershipTests.ownershipNonDemembre.fullOwners = [Owner(name: "Owner1 de 65 ans en 2020", fraction : 40),
                                                          Owner(name: "Owner1 de 55 ans en 2020", fraction : 50),
                                                          Owner(name: "truc", fraction : 10)]
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenueFraction(by: ["Owner1 de 65 ans en 2020"])
        XCTAssertEqual(ownedRevenue, 40)
        ownedRevenue = OwnershipTests.ownershipNonDemembre.ownedRevenueFraction(by: ["Owner1 de 65 ans en 2020",
                                                                                     "Owner1 de 55 ans en 2020"])
        XCTAssertEqual(ownedRevenue, 90)
    }
    
    func test_ownedValues_dismembered() throws {
        let ownedValues = OwnershipTests.ownershipDemembre.ownedValues(ofValue: 100,
                                                                       atEndOf: 2020,
                                                                       evaluationContext: .patrimoine)
        XCTAssertEqual(ownedValues.count, 3)
        let usufructValue = try XCTUnwrap(ownedValues["Owner2 de 55 ans en 2020"])
        XCTAssertGreaterThan(usufructValue, 0)
        let bareValue1 = try XCTUnwrap(ownedValues["Nupropriétaire 1"])
        XCTAssertGreaterThan(bareValue1, 0)
        let bareValue2 = try XCTUnwrap(ownedValues["Nupropriétaire 2"])
        XCTAssertGreaterThan(bareValue2, 0)
        XCTAssertEqual(100, usufructValue + bareValue1 + bareValue2)
    }
    
    func test_ownedValues_not_dismembered() throws {
        let ownedValues = OwnershipTests.ownershipNonDemembre.ownedValues(ofValue: 100,
                                                                          atEndOf: 2020,
                                                                          evaluationContext: .patrimoine)
        XCTAssertEqual(ownedValues.count, 1)
        let value = try XCTUnwrap(ownedValues["Owner1 de 65 ans en 2020"])
        XCTAssertEqual(value, 100)
    }
    
    func test_hasAUniqueFullOwner() {
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.hasAUniqueFullOwner(named: "Owner1 de 65 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipNonDemembre.hasAUniqueFullOwner(named: "inconnu"))
        OwnershipTests.ownershipNonDemembre.fullOwners.append(Owner(name: "Owner2 de 55 ans en 2020", fraction : 100))
        XCTAssertFalse(OwnershipTests.ownershipNonDemembre.hasAUniqueFullOwner(named: "Owner1 de 65 ans en 2020"))
    }
    
    func test_hasAFullOwner() {
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.hasAFullOwner(named: "Owner1 de 65 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipNonDemembre.hasAFullOwner(named: "inconnu"))
    }
    
    func test_hasABareOwner() {
        XCTAssertTrue(OwnershipTests.ownershipDemembre.hasABareOwner(named: "Nupropriétaire 1"))
        XCTAssertTrue(OwnershipTests.ownershipDemembre.hasABareOwner(named: "Nupropriétaire 2"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.hasABareOwner(named: "Inconnu"))
    }

    func test_hasAnUsufructOwner() {
        XCTAssertTrue(OwnershipTests.ownershipDemembre.hasAnUsufructOwner(named: "Owner2 de 55 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.hasAnUsufructOwner(named: "Inconnu"))
    }
    
    func test_providesRevenue() {
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.providesRevenue(to: "Owner1 de 65 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipNonDemembre.providesRevenue(to: "Inconnu"))

        XCTAssertTrue(OwnershipTests.ownershipDemembre.providesRevenue(to: "Owner2 de 55 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.providesRevenue(to: "Inconnu"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.providesRevenue(to: "Nupropriétaire 1"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.providesRevenue(to: "Nupropriétaire 2"))
    }
}
