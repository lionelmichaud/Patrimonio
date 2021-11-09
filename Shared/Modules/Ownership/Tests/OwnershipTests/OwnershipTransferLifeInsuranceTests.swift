//
//  OwnershipTransferLifeInsuranceTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import FiscalModel
@testable import Ownership

class OwnershipTransferLifeInsuranceTests: XCTestCase {
    
    typealias Tests = OwnershipTransferLifeInsuranceTests
    
    static var fullOwner1     : Owner!
    static var fullOwner2     : Owner!
    static var bareOwner1     : Owner!
    static var bareOwner2     : Owner!
    static var usufructOwner1 : Owner!
    static var usufructOwner2 : Owner!
    
    static var fullOwners     = Owners()
    static var bareOwners     = Owners()
    static var usufructOwners = Owners()
    
    static var ownership = Ownership()
    
    static var verbose = true
    
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
    
    // MARK: - Tests
    
    func test_transfer_Life_Insurance_non_demembrée () {
        var ownership = Ownership(ageOf: Tests.ageOf)
        var clause = LifeInsuranceClause()
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (1) la clause bénéficiaire de l'assurane vie est démembrée
        // (a) il n'y a qu'un seul PP de l'assurance vie
        print("Cas B.a.1.a: ")
        print("Test 1a")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant 1", "Enfant 2"]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferLifeInsurance(
                of          : "Défunt",
                spouseName  : "Conjoint",
                childrenName: ["Enfant 1", "Enfant 2"],
                accordingTo : &clause))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
        
        print("Test 1b")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant 1"]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferLifeInsurance(
                of          : "Défunt",
                spouseName  : "Conjoint",
                childrenName: ["Enfant 1"],
                accordingTo : &clause))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
        print("Cas B.a.2: ")
        // (a) le défunt est le seul PP de l'assurance vie
        print("Test 2a")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = false
        clause.fullRecipients    = [Owner(name: "Conjoint", fraction: 100)]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferLifeInsurance(
                of           : "Défunt",
                spouseName   : "Conjoint",
                childrenName : nil,
                accordingTo  : &clause))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
        print("Test 2b")
        // (b) le défunt n'est pas le seul PP de l'assurance vie
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Conjoint", fraction : 50)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = false
        clause.fullRecipients    = [Owner(name: "Conjoint", fraction : 20),
                                    Owner(name: "Enfant 1", fraction : 40),
                                    Owner(name: "Enfant 2", fraction : 40)]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferLifeInsurance(
                of           : "Défunt",
                spouseName   : "Conjoint",
                childrenName : ["Enfant 1", "Enfant 2"],
                accordingTo  : &clause))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction :100)])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (b) le défunt n'est pas un des PP propriétaires du capital de l'assurance vie
        print("Cas B.b: ")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Lionel", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        let ownershipBefore = ownership
        
        clause.isOptional        = false
        clause.isDismembered     = false
        clause.fullRecipients    = [Owner(name: "Conjoint", fraction : 100)]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertNoThrow(
            try ownership.transferLifeInsurance(
                of           : "Défunt",
                spouseName   : "Conjoint",
                childrenName : nil,
                accordingTo  : &clause))
        
        XCTAssertEqual(ownership, ownershipBefore)

        print("APRES : \nOwnership = \n\(String(describing: ownership))")
    }
    
    // MARK: - Assurance Vie DEMEMEBRÉE

    func test_transfer_Life_Insurance_demembrée () {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        var clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (1) le défunt est usufruitier
        print("Cas A.1:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Conjoint",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertNoThrow(try ownership.transferLifeInsurance(
            of           : "Défunt",
            spouseName   : "Conjoint",
            childrenName : ["Enfant 1", "Enfant 2"],
            accordingTo  : &clause))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners
                        .containsSameElements(as: [Owner(name: "Conjoint", fraction : 50),
                                                   Owner(name: "Enfant 1", fraction : 30),
                                                   Owner(name: "Enfant 2", fraction : 20)]))
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")

        // (A) le capital de l'assurane vie est démembré
        // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien
        print("Cas A.3:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Lionel", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Conjoint", fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        let ownershipBefore = ownership
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertNoThrow(try ownership.transferLifeInsurance(
            of           : "Défunt",
            spouseName   : "Conjoint",
            childrenName : ["Enfant 1", "Enfant 2"],
            accordingTo  : &clause))
        
        XCTAssertEqual(ownership, ownershipBefore)

        print("APRES : \nOwnership = \n\(String(describing: ownership))")
    }
    
    func test_transferDismemberedLifeInsurance_do_nothing() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        let clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien
        print("Cas A.3:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Lionel", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Conjoint", fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        let ownershipBefore = ownership
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertNoThrow(try ownership.transferDismemberedLifeInsurance(
                            of           : "Défunt"))
        
        XCTAssertEqual(ownership, ownershipBefore)
        
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
    }

    func test_transferDismemberedLifeInsurance_fail_many_fullOwners() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        let clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (1) le défunt est usufruitier
        // mais pas le seul
        print("Cas A.1:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 50),
                                    Owner(name: "Autre",  fraction : 50)]
        ownership.bareOwners     = [Owner(name: "Conjoint",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertThrowsError(try ownership.transferDismemberedLifeInsurance(
                                of           : "Défunt")) { error in
            XCTAssertEqual(error as! OwnershipError, OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners)
        }
    }
    
    func test_transferDismemberedLifeInsurance_fail_no_bareOwner() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        let clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (1) le défunt est usufruitier
        // mais il n'y a pas de NP
        print("Cas A.1:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 100)]
        ownership.bareOwners     = []
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertThrowsError(try ownership.transferDismemberedLifeInsurance(
                                of           : "Défunt")) { error in
            XCTAssertEqual(error as! OwnershipError, OwnershipError.tryingToTransferAssetWithNoBareOwner)
        }
    }
    
    func test_transferDismemberedLifeInsurance_fail_decedent_is_bareOwner() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        let clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (1) le défunt est usufruitier
        // mais il est aussi un NP
        print("Cas A.1:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertThrowsError(try ownership.transferDismemberedLifeInsurance(
                                of           : "Défunt")) { error in
            XCTAssertEqual(error as! OwnershipError, OwnershipError.tryingToTransferAssetWithDecedentAsBareOwner)
        }
    }
    
    func test_transferDismemberedLifeInsurance_do_transfer() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        let clause = LifeInsuranceClause()
        
        // (A) le capital de l'assurane vie est démembré
        // (1) le défunt est usufruitier
        print("Cas A.1:")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Conjoint",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 20)]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        print(clause)
        
        XCTAssertNoThrow(try ownership.transferDismemberedLifeInsurance(
                            of           : "Défunt"))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners
                        .containsSameElements(as: [Owner(name: "Conjoint", fraction : 50),
                                                   Owner(name: "Enfant 1", fraction : 30),
                                                   Owner(name: "Enfant 2", fraction : 20)]))
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
    }
    
    // MARK: - Assurance Vie NON DEMEMEBRÉE

    func test_transferUndismemberedLifeInsurance() {
        var ownership = Ownership(ageOf: Tests.ageOf)
        var clause = LifeInsuranceClause()
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (1) la clause bénéficiaire de l'assurane vie est démembrée
        // (b) le défunt n'est pas le seul PP de l'assurance vie
        print("Cas B.a.1.b: ")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Conjoint", fraction : 50)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant 1", "Enfant 2"]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(try ownership.transferUndismemberedLifeInsurance(
                            of          : "Défunt",
                            spouseName  : "Conjoint",
                            childrenName: ["Enfant 1", "Enfant 2"],
                            accordingTo : &clause))
        
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
    }
    
    func test_transferUndismemberedLifeInsToUsufructAndBareOwners() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        var clause = LifeInsuranceClause()
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (1) la clause bénéficiaire de l'assurane vie est démembrée
        // (a) il n'y a qu'un seul PP de l'assurance vie
        print("Cas B.a.1.a: ")
        print("Test 1a")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = true
        clause.usufructRecipient = "Conjoint"
        clause.bareRecipients    = ["Enfant 1", "Enfant 2"]
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferUndismemberedLifeInsurance(
                of          : "Défunt",
                spouseName  : "Conjoint",
                childrenName: ["Enfant 1", "Enfant 2"],
                accordingTo : &clause,
                verbose     : Tests.verbose))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
    }

    func test_transferUndismemberedLifeInsFullOwnership() {
        var ownership = Ownership(ageOf: OwnershipTransferLifeInsuranceTests.ageOf)
        var clause = LifeInsuranceClause()
        
        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
        print("Cas B.a.2: ")
        // (a) le défunt est le seul PP de l'assurance vie
        print("Test 2a")
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name : "Défunt", fraction  : 100)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = false
        clause.fullRecipients    = [Owner(name: "Conjoint", fraction: 100)]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferUndismemberedLifeInsurance(
                of           : "Défunt",
                spouseName   : "Conjoint",
                childrenName : ["Enfant 1", "Enfant 2"],
                accordingTo  : &clause))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])
        
        XCTAssertTrue(clause.isValid)
        XCTAssertFalse(clause.isOptional)
        XCTAssertFalse(clause.isDismembered)
        XCTAssertEqual(clause.fullRecipients, [Owner(name: "Conjoint", fraction: 100)])

        print("APRES : \nOwnership = \n\(String(describing: ownership))")
        print("Clause = \n\(String(describing: clause))")

        // (B) le capital de l'assurance vie n'est pas démembré
        // (a) le défunt est un des PP propriétaires du capital de l'assurance vie
        // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
        print("Test 2b")
        // (b) le défunt n'est pas le seul PP de l'assurance vie
        ownership.isDismembered  = false
        ownership.fullOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Conjoint", fraction : 50)]
        ownership.usufructOwners = []
        ownership.bareOwners     = []
        
        clause.isOptional        = false
        clause.isDismembered     = false
        clause.fullRecipients    = [Owner(name: "Conjoint", fraction : 20),
                                    Owner(name: "Enfant 1", fraction : 40),
                                    Owner(name: "Enfant 2", fraction : 40)]
        clause.usufructRecipient = ""
        clause.bareRecipients    = []
        
        print("AVANT : \nOwnership =\n\(String(describing: ownership)) \n Clause =\n\(String(describing: clause))")
        
        XCTAssertNoThrow(
            try ownership.transferUndismemberedLifeInsurance(
                of           : "Défunt",
                spouseName   : "Conjoint",
                childrenName : ["Enfant 1", "Enfant 2"],
                accordingTo  : &clause,
                verbose      : Tests.verbose))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [])

        XCTAssertTrue(clause.isValid)
        XCTAssertFalse(clause.isOptional)
        XCTAssertFalse(clause.isDismembered)
        XCTAssertTrue(clause.fullRecipients
                        .containsSameElements(as: [Owner(name: "Enfant 1", fraction : 50),
                                                   Owner(name: "Enfant 2", fraction : 50)]))
        
        print("APRES : \nOwnership = \n\(String(describing: ownership))")
        print("Clause = \n\(String(describing: clause))")
    }
}
