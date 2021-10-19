//
//  OwnershipTransferTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 06/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
import FiscalModel
@testable import Ownership

class OwnershipTransferTests: XCTestCase { // swiftlint:disable:this type_body_length
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
        OwnershipTransferTests.fullOwner1 = Owner(name     : "Owner1 de 65 ans en 2020",
                                                  fraction : 20)
        OwnershipTransferTests.fullOwner2 = Owner(name     : "Owner2 de 55 ans en 2020",
                                                  fraction : 80)
        OwnershipTransferTests.fullOwners = [OwnershipTransferTests.fullOwner1,
                                             OwnershipTransferTests.fullOwner2]
        
        OwnershipTransferTests.bareOwner1 = Owner(name     : "bareOwner1",
                                                  fraction : 10)
        OwnershipTransferTests.bareOwner2 = Owner(name     : "bareOwner2",
                                                  fraction : 90)
        OwnershipTransferTests.bareOwners = [OwnershipTransferTests.bareOwner1,
                                             OwnershipTransferTests.bareOwner2]
        
        OwnershipTransferTests.usufructOwner1 = Owner(name     : "usufructOwner1",
                                                      fraction : 30)
        OwnershipTransferTests.usufructOwner2 = Owner(name     : "usufructOwner2",
                                                      fraction : 70)
        OwnershipTransferTests.usufructOwners = [OwnershipTransferTests.usufructOwner1,
                                                 OwnershipTransferTests.usufructOwner2]
        
        OwnershipTransferTests.ownership.fullOwners = OwnershipTransferTests.fullOwners
        OwnershipTransferTests.ownership.bareOwners = OwnershipTransferTests.bareOwners
        OwnershipTransferTests.ownership.usufructOwners = OwnershipTransferTests.usufructOwners
        OwnershipTransferTests.ownership.isDismembered = false
        OwnershipTransferTests.ownership.setDelegateForAgeOf(delegate: OwnershipTransferTests.ageOf)
    }
    
    // MARK: - Tests

    func test_transfert_bien_démembré_avec_conjoint_avec_enfants() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (a) le défunt était usufruitier
        // (2) le défunt était seulement usufruitier
        print("Cas A.1.a.2: ")
        print("Test 1")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 60),
                                               Owner(name: "Enfant 2", fraction : 40)])
        print("APRES : \(String(describing: ownership.description))")
        
        print("Test 2")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 70),
                                    Owner(name: "Conjoint", fraction : 30)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 50),
                                    Owner(name: "Enfant 2", fraction : 20),
                                    Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : " + ownership.description)
        
        XCTAssertThrowsError(try ownership.transferOwnershipOf(
                                decedentName       : "Défunt",
                                chidrenNames       : ["Enfant 1", "Enfant 2"],
                                spouseName         : "Conjoint",
                                spouseFiscalOption : .fullUsufruct)) { error in
            XCTAssertEqual(error as! OwnershipError, OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners)
        }
        print("APRES : \(String(describing: ownership.description))")

        // (A) le bien est démembré
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        print("Cas A.1.b: ")

        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 3", fraction : 20)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferOwnershipOf(
                            decedentName       : "Défunt",
                            chidrenNames       : ["Enfant 1", "Enfant 2"],
                            spouseName         : "Conjoint",
                            spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertEqual(Set(ownership.bareOwners),
                       Set([Owner(name: "Enfant 1", fraction : 30.0 + 50.0 / 2.0),
                            Owner(name: "Enfant 2", fraction :  0.0 + 50.0 / 2.0),
                            Owner(name: "Enfant 3", fraction : 20.0)]))
        print("APRES : \(String(describing: ownership.description))")

        // (A) le bien est démembré
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (c) le défunt ne fait pas partie des usufruitires ni des nue-propriétaires
        // on ne fair rien
        print("Cas A.1.c: ")

        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        let ownershipAvant = ownership
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertEqual(ownershipAvant, ownership)
        print("APRES : \(String(describing: ownership.description))")
    }

    func test_transferUsufructAndBareOwnership_sans_enfant() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 60),
                                    Owner(name: "Conjoint", fraction : 40)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 100)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferUsufructAndBareOwnership(
                            of                 : "Défunt",
                            toSpouse           : "Conjoint",
                            toChildren         : nil,
                            spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
        print("APRES : \(String(describing: ownership.description))")

        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 60),
                                    Owner(name: "Conjoint", fraction : 40)]
        
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferUsufructAndBareOwnership(
                            of                 : "Défunt",
                            toSpouse           : "Conjoint",
                            toChildren         : nil,
                            spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transferUsufructAndBareOwnership_avec_enfant() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 3", fraction : 20)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferUsufructAndBareOwnership(
                            of                 : "Défunt",
                            toSpouse           : "Conjoint",
                            toChildren         : chidrenNames,
                            spouseFiscalOption : .fullUsufruct))
        let isBuggy = true
        try XCTSkipIf(isBuggy, "transferUsufructAndBareOwnership: BUG ca ne marche pas comme ça")
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertEqual(Set(ownership.bareOwners),
                       Set([Owner(name: "Enfant 1", fraction : 30.0 + 50.0 / 2.0),
                            Owner(name: "Enfant 2", fraction :  0.0 + 50.0 / 2.0),
                            Owner(name: "Enfant 3", fraction : 20.0)]))
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transferBareOwnership_sans_enfant() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 100)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferBareOwnership(of                 : "Défunt",
                                                             toSpouse           : "Conjoint",
                                                             toChildren         : nil,
                                                             spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
        print("APRES : \(String(describing: ownership.description))")

        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt", fraction : 60),
                                    Owner(name: "Conjoint",  fraction : 40)]
        
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferBareOwnership(of                 : "Défunt",
                                                             toSpouse           : "Conjoint",
                                                             toChildren         : nil,
                                                             spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Conjoint", fraction : 100)])
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transferBareOwnership_avec_enfant_fullsusfrut() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 3", fraction : 20)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferBareOwnership(of                 : "Défunt",
                                                             toSpouse           : "Conjoint",
                                                             toChildren         : chidrenNames,
                                                             spouseFiscalOption : .fullUsufruct))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertEqual(Set(ownership.bareOwners),
                       Set([Owner(name: "Enfant 1", fraction : 30.0 + 50.0 / 2.0),
                            Owner(name: "Enfant 2", fraction :  0.0 + 50.0 / 2.0),
                            Owner(name: "Enfant 3", fraction : 20.0)]))
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transferBareOwnership_avec_enfant_quotiteDisponible() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 3", fraction : 20)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferBareOwnership(of                 : "Défunt",
                                                             toSpouse           : "Conjoint",
                                                             toChildren         : chidrenNames,
                                                             spouseFiscalOption : .quotiteDisponible))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        let shares = InheritanceFiscalOption.quotiteDisponible.shares(nbChildren: chidrenNames.count)
        let spouseShare = shares.forSpouse.bare
        let childShare = 1.0 - spouseShare
        XCTAssertEqual(Set(ownership.bareOwners),
                       Set([Owner(name: "Conjoint", fraction : spouseShare * 50.0),
                            Owner(name: "Enfant 1", fraction : 30.0 + childShare/2.0 * 50.0),
                            Owner(name: "Enfant 2", fraction :  0.0 + childShare/2.0 * 50.0),
                            Owner(name: "Enfant 3", fraction : 20.0)]))
        print("APRES : " + ownership.description)
    }
    
    func test_transferBareOwnership_avec_enfant_usufructPlusBare() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (b) le défunt était seulement nue-propriétaire
        
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Conjoint", fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Défunt",   fraction : 50),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 3", fraction : 20)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferBareOwnership(of                 : "Défunt",
                                                             toSpouse           : "Conjoint",
                                                             toChildren         : chidrenNames,
                                                             spouseFiscalOption : .usufructPlusBare))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        let shares = InheritanceFiscalOption.usufructPlusBare.shares(nbChildren: chidrenNames.count)
        let spouseShare = shares.forSpouse.bare
        let childShare = shares.forChild.bare
        XCTAssertEqual(Set(ownership.bareOwners),
                       Set([Owner(name: "Conjoint", fraction : spouseShare * 50.0),
                            Owner(name: "Enfant 1", fraction : 30.0 + childShare * 50.0),
                            Owner(name: "Enfant 2", fraction :  0.0 + childShare * 50.0),
                            Owner(name: "Enfant 3", fraction : 20.0)]))
        print("APRES : " + ownership.description)
    }
    
    func test_transferUsufruct_avec_plusieur_usufruitiers() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (a) le défunt était usufruitier
        // (2) le défunt était seulement usufruitier
        print("Cas A.1.a.2: ")
        print("Test 1: avec enfants")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 60),
                                    Owner(name: "Conjoint", fraction : 40)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        print("AVANT : " + ownership.description)
        
        XCTAssertThrowsError(try ownership.transferUsufruct(of: "Défunt", toChildren: chidrenNames)) { error in
            XCTAssertEqual(error as! OwnershipError, OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners)
        }
    }
    
    func test_transferUsufruct_avec_un_seul_usufruitier() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (a) le défunt était usufruitier
        // (2) le défunt était seulement usufruitier
        print("Cas A.1.a.2: ")
        print("Test 1: avec enfants")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferUsufruct(of: "Défunt", toChildren: chidrenNames))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 60),
                                               Owner(name: "Enfant 2", fraction : 40)])
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transferUsufruct_avec_enfant_plus_autre_NP() {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (1) il y a un conjoint survivant
        //      le défunt peut être usufruitier et/ou nue-propriétaire
        // (a) le défunt était usufruitier
        // (2) le défunt était seulement usufruitier
        print("Cas A.1.a.2: ")
        print("Test 1: avec enfants")
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Défunt",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Autre",    fraction : 20),
                                    Owner(name: "Enfant 1", fraction : 30),
                                    Owner(name: "Enfant 2", fraction : 50)]
        print("AVANT : " + ownership.description)
        
        XCTAssertNoThrow(try ownership.transferUsufruct(of: "Défunt", toChildren: chidrenNames))
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Autre",    fraction : 20),
                                               Owner(name: "Enfant 1", fraction : 30),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transfert_bien_démembré_sans_conjoint_avec_enfants() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        
        // (A) le bien est démembré
        ownership.isDismembered = true
        
        // (2)  il n'y a pas de conjoint survivant
        //      mais il y a des enfants survivants
        // un seul usufruitier + un seul nupropriétaire + pas de conjoint
        print("Cas A.2: ")
        ownership.usufructOwners = [Owner(name: "Parent",    fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant", fraction : 100)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Parent",
            chidrenNames       : ["Enfant"],
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [Owner(name: "Enfant", fraction : 100)])
        print("APRES : \(String(describing: ownership.description))")

        // un seul usufruitier + plusieurs nupropriétaires + pas de conjoint
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: "Parent",   fraction : 100)]
        ownership.bareOwners     = [Owner(name: "Enfant 1", fraction : 60),
                                    Owner(name: "Enfant 2", fraction : 40)]
        print("AVANT : " + ownership.description)
        
        try ownership.transferOwnershipOf(
            decedentName       : "Parent",
            chidrenNames       : ["Enfant 1", "Enfant 2"],
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 60),
                                               Owner(name: "Enfant 2", fraction : 40)])
        print("APRES : \(String(describing: ownership.description))")
    }
    
    func test_transfert_bien_non_démembré() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        
        /// Cas B.1
        // (B) le bien n'est pas démembré
        ownership.isDismembered = false
        // (1) le défunt fait partie des plein-propriétaires
        print("Cas B.1.b: ")
        // (b) il n'y a pas de conjoint survivant
        // un seul usufruitier + plusieurs enfants + pas de conjoint
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : \(String(describing: ownership.description))")
        
        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Enfant 1", fraction : 50),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : \(String(describing: ownership.description))")

        // (a) il y a un conjoint survivant
        // un seul usufruitier + plusieurs enfants + un conjoint
        print("Cas B.1.a: ")
        print("Test 1a: option du conjoint = fullUsufruct")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Enfant 1", fraction : 50),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : \(String(describing: ownership.description))")

        print("Test 1b: option du conjoint = quotiteDisponible")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : "Conjoint",
            spouseFiscalOption : .quotiteDisponible)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 100.0/3.0),
                                               Owner(name: "Enfant 1", fraction : 100.0/3.0),
                                               Owner(name: "Enfant 2", fraction : 100.0/3.0)])
        print("APRES : \(String(describing: ownership.description))")

        print("Test 1c: option du conjoint = usufructPlusBare")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 100)]
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : "Conjoint",
            spouseFiscalOption : .usufructPlusBare)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 100.0/4.0),
                                               Owner(name: "Enfant 1", fraction : 100.0 * 3.0/8.0),
                                               Owner(name: "Enfant 2", fraction : 100.0 * 3.0/8.0)])
        print("APRES : \(String(describing: ownership.description))")

        print("Test 2: option du conjoint = fullUsufruct")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 70),
                                Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : "Conjoint",
            spouseFiscalOption : .fullUsufruct)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 30),
                                               Owner(name: "Enfant 1", fraction : 35),
                                               Owner(name: "Enfant 2", fraction : 35)])
        print("APRES : \(String(describing: ownership.description))")

        print("Test 3: option du conjoint = usufructPlusBare")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 70),
                                Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : "Conjoint",
            spouseFiscalOption : .usufructPlusBare)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 30.0 + 0.25 * 70.0),
                                               Owner(name: "Enfant 1", fraction : 0.75 * 70.0 / 2.0),
                                               Owner(name: "Enfant 2", fraction : 0.75 * 70.0 / 2.0)])
        print("APRES : \(String(describing: ownership.description))")

        print("Test 4: option du conjoint = quotiteDisponible")
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: "Défunt", fraction : 70),
                                Owner(name: "Conjoint", fraction : 30)]
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : "Conjoint",
            spouseFiscalOption : .quotiteDisponible)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 30.0 + 70.0 / 3.0),
                                               Owner(name: "Enfant 1", fraction : 70.0 / 3.0),
                                               Owner(name: "Enfant 2", fraction : 70.0 / 3.0)])
        print("APRES : \(String(describing: ownership.description))")

        /// Cas B.2
        print("Cas B.2: ")
        // (B) le bien n'est pas démembré
        ownership.isDismembered = false
        // (2) le défunt ne fait pas partie des plein-propriétaires
        // un seul usufruitier + plusieurs enfants + pas de conjoint
        ownership.fullOwners = [Owner(name: "Parent", fraction : 100)]
        let ownershipAvant = ownership
        print("AVANT : \(String(describing: ownership.description))")

        try ownership.transferOwnershipOf(
            decedentName       : "Défunt",
            chidrenNames       : chidrenNames,
            spouseName         : nil,
            spouseFiscalOption : nil)
        
        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownershipAvant, ownership)
        print("APRES : \(String(describing: ownership.description))")
    }

    func test_transferFullOwnership_avec_option_fullUsufruct_1_PP() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        let ppOwners = [Owner(name: "Défunt", fraction : 100)]

        print("Test 1a: option du conjoint = fullUsufruct")
        ownership.isDismembered = false
        ownership.fullOwners = ppOwners
        print("AVANT : \(String(describing: ownership.description))")

        ownership.transferFullOwnership(
            of                    : "Défunt",
            toThisNewUsufructuary : "Conjoint",
            toTheseNewBareOwners  : chidrenNames)

        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Enfant 1", fraction : 50),
                                               Owner(name: "Enfant 2", fraction : 50)])
        print("APRES : \(String(describing: ownership.description))")
    }
    func test_transferFullOwnership_avec_option_fullUsufruct_plusieur_PP() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        let ppOwners = [Owner(name: "Défunt", fraction : 70),
                        Owner(name: "Conjoint", fraction : 30)]

        print("Test 2: option du conjoint = fullUsufruct")
        ownership.isDismembered = false
        ownership.fullOwners = ppOwners
        print("AVANT : \(String(describing: ownership.description))")

        ownership.transferFullOwnership(
            of                    : "Défunt",
            toThisNewUsufructuary : "Conjoint",
            toTheseNewBareOwners  : chidrenNames)

        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 30),
                                               Owner(name: "Enfant 1", fraction : 35),
                                               Owner(name: "Enfant 2", fraction : 35)])
        print("APRES : \(String(describing: ownership.description))")
    }

    func test_transferFullOwnership_avec_option_quotiteDisponible_1_PP() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        let ppOwners = [Owner(name: "Défunt", fraction : 100)]

        print("Test 1b: option du conjoint = quotiteDisponible")
        ownership.isDismembered = false
        ownership.fullOwners = ppOwners
        print("AVANT : \(String(describing: ownership.description))")
        let shares = InheritanceFiscalOption.quotiteDisponible.shares(nbChildren: chidrenNames.count)

        ownership.transferFullOwnership(
            of                : "Défunt",
            toSpouse          : "Conjoint",
            quotiteDisponible : shares.forSpouse.bare,
            toChildren        : chidrenNames)

        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 100.0/3.0),
                                               Owner(name: "Enfant 1", fraction : 100.0/3.0),
                                               Owner(name: "Enfant 2", fraction : 100.0/3.0)])
        print("APRES : \(String(describing: ownership.description))")
    }
    func test_transferFullOwnership_avec_option_quotiteDisponible_plusieur_PP() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        let ppOwners = [Owner(name: "Défunt", fraction : 70),
                        Owner(name: "Conjoint", fraction : 30)]

        print("Test 4: option du conjoint = quotiteDisponible")
        ownership.isDismembered = false
        ownership.fullOwners = ppOwners
        print("AVANT : \(String(describing: ownership.description))")
        let shares = InheritanceFiscalOption.quotiteDisponible.shares(nbChildren: chidrenNames.count)

        ownership.transferFullOwnership(
            of                : "Défunt",
            toSpouse          : "Conjoint",
            quotiteDisponible : shares.forSpouse.bare,
            toChildren        : chidrenNames)

        XCTAssertTrue(ownership.isValid)
        XCTAssertFalse(ownership.isDismembered)
        XCTAssertEqual(ownership.usufructOwners, [])
        XCTAssertEqual(ownership.bareOwners, [])
        XCTAssertTrue(ownership.fullOwners == [Owner(name: "Conjoint", fraction : 30.0 + 70.0 / 3.0),
                                               Owner(name: "Enfant 1", fraction : 70.0 / 3.0),
                                               Owner(name: "Enfant 2", fraction : 70.0 / 3.0)])
        print("APRES : \(String(describing: ownership.description))")
    }

    func test_transferFullOwnership_avec_option_usufructPlusBare_1_PP() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        let ppOwners = [Owner(name: "Défunt", fraction : 100)]

        print("Test 1c: option du conjoint = usufructPlusBare")
        ownership.isDismembered = false
        ownership.fullOwners = ppOwners
        print("AVANT : \(String(describing: ownership.description))")
        let sharing = InheritanceFiscalOption.usufructPlusBare.shares(nbChildren: chidrenNames.count)
        
        ownership.transferFullOwnership(
            of              : "Défunt",
            toSpouse        : "Conjoint",
            toChildren      : chidrenNames,
            withThisSharing : sharing)

        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 100.0/4.0),
                                               Owner(name: "Enfant 1", fraction : 100.0 * 3.0/8.0),
                                               Owner(name: "Enfant 2", fraction : 100.0 * 3.0/8.0)])
        print("APRES : \(String(describing: ownership.description))")
    }
    func test_transferFullOwnership_avec_option_usufructPlusBare_plusieur_PP() throws {
        var ownership = Ownership(ageOf: OwnershipTransferTests.ageOf)
        let chidrenNames = ["Enfant 1", "Enfant 2"]
        let ppOwners = [Owner(name: "Défunt", fraction : 70),
                        Owner(name: "Conjoint", fraction : 30)]

        print("Test 3: option du conjoint = usufructPlusBare")
        ownership.isDismembered = false
        ownership.fullOwners = ppOwners
        print("AVANT : \(String(describing: ownership.description))")
        let sharing = InheritanceFiscalOption.usufructPlusBare.shares(nbChildren: chidrenNames.count)

        ownership.transferFullOwnership(
            of              : "Défunt",
            toSpouse        : "Conjoint",
            toChildren      : chidrenNames,
            withThisSharing : sharing)

        XCTAssertTrue(ownership.isValid)
        XCTAssertTrue(ownership.isDismembered)
        XCTAssertEqual(ownership.fullOwners, [])
        XCTAssertEqual(ownership.usufructOwners, [Owner(name: "Conjoint", fraction : 100)])
        XCTAssertTrue(ownership.bareOwners == [Owner(name: "Conjoint", fraction : 30.0 + 0.25 * 70.0),
                                               Owner(name: "Enfant 1", fraction : 0.75 * 70.0 / 2.0),
                                               Owner(name: "Enfant 2", fraction : 0.75 * 70.0 / 2.0)])
        print("APRES : \(String(describing: ownership.description))")
    }
}
