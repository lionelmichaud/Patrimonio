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
    static var usufruct = 0.4
    static var barevalue = 0.6
    struct DemembrementProvider: DemembrementProviderP {
        func demembrement(of assetValue   : Double,
                          usufructuaryAge : Int) throws -> (usufructValue : Double,
                                                            bareValue     : Double) {
            return (usufructValue : OwnershipTests.usufruct * assetValue,
                    bareValue     : OwnershipTests.barevalue * assetValue)
        }
    }
    
    override class func setUp() {
        super.setUp()
        let demembrement = DemembrementProvider()
        
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

        var ownership = OwnershipTests.ownershipNonDemembre
        ownership.fullOwners = []
        XCTAssertTrue(ownership.isValid)
    }
    
    func test_isNotValid() {
        var ownership = OwnershipTests.ownershipDemembre
        ownership.usufructOwners =
        [Owner(name: "Owner2 de 55 ans en 2020", fraction : 50)]
        XCTAssertFalse(ownership.isValid)

        ownership = OwnershipTests.ownershipDemembre
        ownership.bareOwners =
        [Owner(name: "Nupropriétaire 1", fraction : 40),
         Owner(name: "Nupropriétaire 2", fraction : 50)]
        XCTAssertFalse(ownership.isValid)

        ownership = OwnershipTests.ownershipDemembre
        ownership.usufructOwners = []
        XCTAssertFalse(ownership.isValid)

        ownership = OwnershipTests.ownershipDemembre
        ownership.bareOwners = []
        XCTAssertFalse(ownership.isValid)

        ownership = OwnershipTests.ownershipNonDemembre
        ownership.fullOwners = [Owner(name: "Owner1 de 65 ans en 2020", fraction : 50)]
        XCTAssertFalse(ownership.isValid)
    }
    
    func test_make_dismembered() {
        let fullOwners = OwnershipTests.ownershipNonDemembre.fullOwners
        OwnershipTests.ownershipNonDemembre.isDismembered = true
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.isDismembered)
        XCTAssertEqual(OwnershipTests.ownershipNonDemembre.bareOwners, fullOwners)
        XCTAssertEqual(OwnershipTests.ownershipNonDemembre.usufructOwners, fullOwners)
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
    
    func test_hasAUniqueUsufructOwner() {
        XCTAssertTrue(OwnershipTests.ownershipDemembre.hasAUniqueUsufructOwner(named: "Owner2 de 55 ans en 2020"))
        OwnershipTests.ownershipDemembre.usufructOwners.append(Owner(name: "Owner1 de 55 ans en 2020", fraction : 100))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.hasAUniqueUsufructOwner(named: "Owner1 de 55 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.hasAUniqueUsufructOwner(named: "Owner2 de 55 ans en 2020"))
    }
    
    func test_providesRevenue() {
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.providesRevenue(to: "Owner1 de 65 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipNonDemembre.providesRevenue(to: "Inconnu"))

        XCTAssertTrue(OwnershipTests.ownershipDemembre.providesRevenue(to: "Owner2 de 55 ans en 2020"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.providesRevenue(to: "Inconnu"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.providesRevenue(to: "Nupropriétaire 1"))
        XCTAssertFalse(OwnershipTests.ownershipDemembre.providesRevenue(to: "Nupropriétaire 2"))
    }

    func test_groupShares_dismembered() {
        OwnershipTests.ownershipDemembre.usufructOwners = [Owner(name: "UF_Owner1", fraction : 30),
                                                           Owner(name: "UF_Owner2", fraction : 20),
                                                           Owner(name: "UF_Owner1", fraction : 50)]
        OwnershipTests.ownershipDemembre.bareOwners = [Owner(name: "B_Owner1", fraction : 30),
                                                       Owner(name: "B_Owner2", fraction : 20),
                                                       Owner(name: "B_Owner1", fraction : 50)]

        OwnershipTests.ownershipDemembre.groupShares()

        XCTAssertEqual(OwnershipTests.ownershipDemembre.usufructOwners.count, 2)
        XCTAssertTrue(OwnershipTests.ownershipDemembre.usufructOwners
                        .contains(Owner(name: "UF_Owner1", fraction : 80)))
        XCTAssertTrue(OwnershipTests.ownershipDemembre.usufructOwners
                        .contains(Owner(name: "UF_Owner2", fraction : 20)))

        XCTAssertEqual(OwnershipTests.ownershipDemembre.bareOwners.count, 2)
        XCTAssertTrue(OwnershipTests.ownershipDemembre.bareOwners
                        .contains(Owner(name: "B_Owner1", fraction : 80)))
        XCTAssertTrue(OwnershipTests.ownershipDemembre.bareOwners
                        .contains(Owner(name: "B_Owner2", fraction : 20)))
    }

    func test_groupShares_not_dismembered() {
        OwnershipTests.ownershipNonDemembre.fullOwners = [Owner(name: "Owner1", fraction : 30),
                                                          Owner(name: "Owner2", fraction : 20),
                                                          Owner(name: "Owner1", fraction : 50)]

        OwnershipTests.ownershipNonDemembre.groupShares()

        XCTAssertEqual(OwnershipTests.ownershipNonDemembre.fullOwners.count, 2)
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.fullOwners
                        .contains(Owner(name: "Owner1", fraction : 80)))
        XCTAssertTrue(OwnershipTests.ownershipNonDemembre.fullOwners
                        .contains(Owner(name: "Owner2", fraction : 20)))
    }

    func test_groupShares_dismembered_regroupement() {
        OwnershipTests.ownershipDemembre.usufructOwners = [Owner(name: "Owner1", fraction : 30),
                                                           Owner(name: "Owner2", fraction : 20),
                                                           Owner(name: "Owner1", fraction : 50)]
        OwnershipTests.ownershipDemembre.bareOwners = [Owner(name: "Owner1", fraction : 30),
                                                       Owner(name: "Owner2", fraction : 20),
                                                       Owner(name: "Owner1", fraction : 50)]

        OwnershipTests.ownershipDemembre.groupShares()

        XCTAssertFalse(OwnershipTests.ownershipDemembre.isDismembered)
        XCTAssertTrue(OwnershipTests.ownershipDemembre.usufructOwners.isEmpty)
        XCTAssertTrue(OwnershipTests.ownershipDemembre.bareOwners.isEmpty)
        XCTAssertEqual(OwnershipTests.ownershipDemembre.fullOwners.count, 2)
        XCTAssertTrue(OwnershipTests.ownershipDemembre.fullOwners
                        .contains(Owner(name: "Owner1", fraction : 80)))
        XCTAssertTrue(OwnershipTests.ownershipDemembre.fullOwners
                        .contains(Owner(name: "Owner2", fraction : 20)))
    }

    func test_ownership_demembrement() throws {
        var (usufructValue, bareValue) : (Double, Double) = (0, 0)
        XCTAssertNoThrow((usufructValue, bareValue) =
                            try OwnershipTests.ownershipDemembre.demembrement(ofValue: 100, atEndOf: 2020))
        XCTAssertEqual(100.0, usufructValue + bareValue)
    }
    
    func test_ownership_demembrementPercentage() throws {
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
        // 1 UF
        var ownedValues = OwnershipTests.ownershipDemembre.ownedValues(ofValue: 100,
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
        XCTAssertEqual(ownedValues, ["Owner2 de 55 ans en 2020": 100.0 * OwnershipTests.usufruct,
                                     "Nupropriétaire 1": 100.0 * 0.4 * OwnershipTests.barevalue,
                                     "Nupropriétaire 2": 100.0 * 0.6 * OwnershipTests.barevalue])
        
        var ownershipDemembre = Ownership(ageOf: OwnableTests.ageOf)
        ownershipDemembre.isDismembered  = true
        ownershipDemembre.usufructOwners = [Owner(name: "Owner2 de 55 ans en 2020", fraction : 100)]
        ownershipDemembre.bareOwners     = [Owner(name: "Owner2 de 55 ans en 2020", fraction : 20),
                                            Owner(name: "Nupropriétaire 1", fraction : 30),
                                            Owner(name: "Nupropriétaire 2", fraction : 50)]
        ownedValues = ownershipDemembre.ownedValues(ofValue: 100,
                                                    atEndOf: 2020,
                                                    evaluationContext: .patrimoine)
        XCTAssertEqual(ownedValues.count, 3)
        XCTAssertEqual(ownedValues, ["Owner2 de 55 ans en 2020": 100.0 * OwnershipTests.usufruct + 100.0 * 0.2 * OwnershipTests.barevalue,
                                     "Nupropriétaire 1": 100.0 * 0.3 * OwnershipTests.barevalue,
                                     "Nupropriétaire 2": 100.0 * 0.5 * OwnershipTests.barevalue])
    }
    
    func test_ownedValues_not_dismembered() throws {
        // 1 NP
        var ownedValues = OwnershipTests.ownershipNonDemembre.ownedValues(ofValue: 100,
                                                                          atEndOf: 2020,
                                                                          evaluationContext: .patrimoine)
        XCTAssertEqual(ownedValues.count, 1)
        let value = try XCTUnwrap(ownedValues["Owner1 de 65 ans en 2020"])
        XCTAssertEqual(value, 100)
        
        // 2 NP
        var ownershipNonDemembre = Ownership(ageOf: OwnableTests.ageOf)
        ownershipNonDemembre.isDismembered = false
        ownershipNonDemembre.fullOwners = [Owner(name: "Owner1", fraction : 70),
                                           Owner(name: "Owner2", fraction : 30)]
        ownedValues = ownershipNonDemembre.ownedValues(ofValue: 100,
                                                       atEndOf: 2020,
                                                       evaluationContext: .patrimoine)
        
        XCTAssertEqual(ownedValues.count, 2)
        XCTAssertEqual(ownedValues, ["Owner1": 100.0 * 0.7,
                                     "Owner2": 100.0 * 0.3])
    }
}
