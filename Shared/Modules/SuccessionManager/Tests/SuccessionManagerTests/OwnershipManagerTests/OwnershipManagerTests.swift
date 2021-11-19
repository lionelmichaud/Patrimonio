import XCTest
@testable import SuccessionManager
import Succession
import ModelEnvironment
import FiscalModel
import DateBoundary
import PersonModel
import FamilyModel
import AssetsModel
import Ownership
import PatrimoineModel
import NamedValue

final class OwnershipManagerTests: XCTestCase {

    typealias Tests = OwnershipManagerTests
    
    static var manager     : OwnershipManager!
    static var model       : Model!
    static var fiscalModel : Fiscal.Model!
    static var family      : Family!
    static var patrimoin   : Patrimoin!
    
    static let verbose = true
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        // charger le model
        XCTAssertNoThrow(model = Model(fromBundle: Bundle.module),
                         "Failed to read Model from Module Bundle \(String(describing: Bundle.module.resourcePath))")
        fiscalModel = model.fiscalModel
        
        /// gérer les dépendances entre le Modèle et les objets applicatifs
        // Injection de Fiscal
        RealEstateAsset.setFiscalModelProvider(model.fiscalModel)
        SCPI.setFiscalModelProvider(model.fiscalModel)
        PeriodicInvestement.setFiscalModelProvider(model.fiscalModel)
        FreeInvestement.setFiscalModelProvider(model.fiscalModel)
        Ownership.setDemembrementProviderP(model.fiscalModel.demembrement)
        
        // Injection de Economy
        SCPI.setInflationProvider(model.economyModel)
        PeriodicInvestement.setEconomyModelProvider(model.economyModel)
        FreeInvestement.setEconomyModelProvider(model.economyModel)
        
        // charger la famille
        XCTAssertNoThrow(family = try Family(fromBundle: Bundle.module, using: model),
                         "Failed to read Family from Module Bundle \(String(describing: Bundle.module.resourcePath))")
        
        // charger le patrimoine
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = family
        patrimoin = Patrimoin(fromBundle: Bundle.module,
                              fileNamePrefix: "OwnerMng_")
        
        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(family)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(family)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = family
        
        // initialiser le Manager
        manager = OwnershipManager(of      : family,
                                   atEndOf : 2021,
                                   run     : 1)
    }
    
    func test_manageRecipientDeath_undismembered() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        var clause = LifeInsuranceClause()
        clause.isDismembered = false
        
        // (B) la clause n'est pas démembrée
        // (1) le défunt est un des PP désignés dans la clause
        // (a) il y a d'autres PP dans la clause
        clause.fullRecipients = [Owner(name: decedentName, fraction: 50),
                                 Owner(name: spouseName,   fraction: 50)]
        
        Tests.manager.manageRecipientDeath(decedentName : decedentName,
                                           withClause   : &clause,
                                           childrenName : nil)
        
        var expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: spouseName, fraction: 100)]
        
        XCTAssertEqual(expectedClause, clause)
        
        // (B) la clause n'est pas démembrée
        // (1) le défunt est un des PP désignés dans la clause
        // (b) il n'y a pas d'autres PP dans la clause
        // (1) il ya des enfants héritiers
        clause.isDismembered = false
        clause.fullRecipients = [Owner(name: decedentName, fraction: 100)]

        Tests.manager.manageRecipientDeath(decedentName : decedentName,
                                           withClause   : &clause,
                                           childrenName : childrenName)
        
        expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: childrenName[0], fraction: 50),
                                         Owner(name: childrenName[1], fraction: 50)]
        
        XCTAssertEqual(expectedClause, clause)
    }
    
    func test_manageRecipientDeath_dismembered() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        var clause = LifeInsuranceClause()
        clause.isDismembered = true

        // (A) la clause est est démembrée
        // (1) le défunt est l'usufruitier désigné dans la clause
        clause.usufructRecipient = decedentName
        clause.bareRecipients    = childrenName
        
        Tests.manager.manageRecipientDeath(decedentName : decedentName,
                                           withClause   : &clause,
                                           childrenName : nil)
        
        var expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: childrenName[0], fraction: 50),
                                         Owner(name: childrenName[1], fraction: 50)]
        
        XCTAssertEqual(expectedClause, clause)

        // (A) la clause est est démembrée
        // (2) le défunt est un des NP désignés dans la clause
        // (a) il y a d'autres NP
        clause.isDismembered     = true
        clause.fullRecipients    = []
        clause.usufructRecipient = spouseName
        clause.bareRecipients    = childrenName + [decedentName]
        
        Tests.manager.manageRecipientDeath(decedentName : decedentName,
                                           withClause   : &clause,
                                           childrenName : nil)
        
        expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered     = true
        expectedClause.usufructRecipient = spouseName
        expectedClause.bareRecipients    = childrenName
        
        XCTAssertEqual(expectedClause, clause)

        // (A) la clause est est démembrée
        // (2) le défunt est un des NP désignés dans la clause
        // (b) il n'y a pas d'autres NP
        clause.isDismembered     = true
        clause.fullRecipients    = []
        clause.usufructRecipient = spouseName
        clause.bareRecipients    = [decedentName]

        Tests.manager.manageRecipientDeath(decedentName : decedentName,
                                           withClause   : &clause,
                                           childrenName : nil)
        
        expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered     = false
        expectedClause.fullRecipients    = [Owner(name: spouseName, fraction: 100)]
        expectedClause.usufructRecipient = ""
        expectedClause.bareRecipients    = []
        
        XCTAssertEqual(expectedClause, clause)
    }
    
    func test_modifyClausesWhereDecedentIsFuturRecipient() {
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]

        XCTAssertNoThrow(try Tests.manager.modifyClausesWhereDecedentIsFuturRecipient(
                            decedentName : spouseName,
                            childrenName : childrenName,
                            withAssets   : &Tests.patrimoin.assets))
        
        let AvBoursoLionel = Tests.patrimoin.assets.freeInvests.items.first {
            $0.name == "AV Lionel Bourso"
        }
        
        var expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: childrenName[0], fraction: 50),
                                         Owner(name: childrenName[1], fraction: 50)]
        
        XCTAssertEqual(expectedClause, AvBoursoLionel!.clause!)

        let AvAferLionel = Tests.patrimoin.assets.freeInvests.items.first {
            $0.name == "AV Lionel AFER"
        }
        
        expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: childrenName[0], fraction: 50),
                                         Owner(name: childrenName[1], fraction: 50)]
        
        XCTAssertEqual(expectedClause, AvAferLionel!.clause!)
    }
    
    func test_childrenNetSellableAssets() {
        let sellableAssets =
            Tests.manager.childrenNetSellableAssets(withAssets      : Tests.patrimoin.assets,
                                                    withLiabilities : Tests.patrimoin.liabilities)
        
        let expected = ["M. Arthur MICHAUD"    : 0.0,
                        "Mme. Lou-Ann MICHAUD" : 0.0]
        
        XCTAssertEqual(expected, sellableAssets)
    }
    
    func test_childrenSellableCapitalAfterInheritance() {
        let decedentName = "M. Lionel MICHAUD"
        let sellableAssets =
            Tests.manager.childrenNetSellableAssetsAfterInheritance(receivedFrom    : decedentName,
                                                                    withAssets      : Tests.patrimoin.assets,
                                                                    withLiabilities : Tests.patrimoin.liabilities)
        // 100% UF pour le conjoint
        let expected = ["M. Arthur MICHAUD"    : 0.0,
                        "Mme. Lou-Ann MICHAUD" : 0.0]
        
        XCTAssertEqual(expected, sellableAssets)
    }
    
    func test_missingCapital() {
        let decedentName = "M. Lionel MICHAUD"
        
        //                      = pris en compte * part héritage * valeur
        let therory_period_tonl_enf = 1.0 * 0.5 * (0.0 + 10_000.0)
        //let therory_period_tonv_enf = 0.0 * 0.0 * (0.0 +  5_000.0)
        
        //                          = pris en compte * UF/NP * part héritage * valeur
        //let theory_free_peal        = 0.0 * 1.0 * ( 23_900.0 + 149_899.0)
        //let theory_free_livAl       = 0.0 * 1.0 * (      0.0 +  23_063.0)
        let theory_free_av_boul_van = 1.0 * 1.0 * 1.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_boul_enf = 1.0 * 0.5 * 0.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_afel_van = 1.0 * 0.5 * 1.0 * (406_533.0 +  96_805.0)
        let theory_free_av_afel_enf = 1.0 * 0.5 * 0.5 * (406_533.0 +  96_805.0)
        //let theory_free_av_afev     = 0.0 * 0.5 * ( 29_000.0 +  31_213.0)
        
        let capitauxTaxables = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                                "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                                "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]

        let capitauxReceivedBrut = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van + 2 * theory_free_av_afel_enf,
                                    "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf,
                                    "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf]
        
        let taxeEnfant = max(0.0, (capitauxTaxables["M. Arthur MICHAUD"]! - 0.5 * 152500.0) * 0.2)
        
        var capitauxDeces = LifeInsuranceSuccessionManager.NameCapitauxDecesDico()
        capitauxDeces["M. Arthur MICHAUD"] =
            LifeInsuranceSuccessionManager
            .CapitauxDeces(received: (brut: capitauxReceivedBrut["Mme. Lou-Ann MICHAUD"]!,
                                      net: capitauxReceivedBrut["M. Arthur MICHAUD"]! - taxeEnfant))
        capitauxDeces["Mme. Lou-Ann MICHAUD"] =
            LifeInsuranceSuccessionManager
            .CapitauxDeces(received: (brut: capitauxReceivedBrut["Mme. Lou-Ann MICHAUD"]!,
                                      net: capitauxReceivedBrut["Mme. Lou-Ann MICHAUD"]! - taxeEnfant))

        let taxes = ["M. Arthur MICHAUD"    : Double(taxeEnfant),
                     "Mme. Lou-Ann MICHAUD" : Double(taxeEnfant)]
        
        let missingCapital =
            Tests.manager.missingCapital(decedentName          : decedentName,
                                         withAssets            : Tests.patrimoin.assets,
                                         withLiabilities       : Tests.patrimoin.liabilities,
                                         toPayFor              : taxes,
                                         capitauxDecesRecusNet : capitauxDeces,
                                         verbose               : Tests.verbose)
        
        // 100% UF pour le conjoint
        let correctionFactor = 1.3
        let expectedMissingCapital =
            ["M. Arthur MICHAUD"    : correctionFactor * taxes["M. Arthur MICHAUD"]! - capitauxDeces["M. Arthur MICHAUD"]!.received.brut,
             "Mme. Lou-Ann MICHAUD" : correctionFactor * taxes["Mme. Lou-Ann MICHAUD"]! - capitauxDeces["Mme. Lou-Ann MICHAUD"]!.received.brut
            ]
        
        XCTAssertEqual(expectedMissingCapital, missingCapital)
    }
    
    func test_modifyClause_pas_assez_d_heritage() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]

        var missingCapital = ["M. Arthur MICHAUD"    : 100_000.0,
                              "Mme. Lou-Ann MICHAUD" : 100_000.0]
        
        var AvBoursoLionel = Tests.patrimoin.assets.freeInvests.items.first {
            $0.name == "AV Lionel Bourso"
        }

        XCTAssertNoThrow(try Tests.manager.modifyClause(
                            of           : &AvBoursoLionel!,
                            toGet        : &missingCapital,
                            decedentName : decedentName,
                            conjointName : spouseName,
                            verbose: Tests.verbose))
        
        var expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: childrenName[0], fraction: 50),
                                         Owner(name: childrenName[1], fraction: 50)]
        
        XCTAssertEqual(expectedClause, AvBoursoLionel!.clause!)
        XCTAssertGreaterThan(missingCapital["M. Arthur MICHAUD"]!, 0.0)
        XCTAssertGreaterThan(missingCapital["Mme. Lou-Ann MICHAUD"]!, 0.0)
    }
    
    func test_modifyClause_assez_d_heritage() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        
        var missingCapital = ["M. Arthur MICHAUD"    : 10_000.0,
                              "Mme. Lou-Ann MICHAUD" : 10_000.0]
        
        var AvBoursoLionel = Tests.patrimoin.assets.freeInvests.items.first {
            $0.name == "AV Lionel Bourso"
        }
        
        XCTAssertNoThrow(try Tests.manager.modifyClause(
                            of           : &AvBoursoLionel!,
                            toGet        : &missingCapital,
                            decedentName : decedentName,
                            conjointName : spouseName,
                            verbose: Tests.verbose))
        
        let expectedChildShare = 10_000.0 / (104_594.0 + 2_621.0) * 100.0
        let expectedSpouseShare = 100.0 - 2.0 * expectedChildShare
        var expectedClause = LifeInsuranceClause()
        expectedClause.isDismembered = false
        expectedClause.fullRecipients = [Owner(name: spouseName,      fraction: expectedSpouseShare),
                                         Owner(name: childrenName[0], fraction: expectedChildShare),
                                         Owner(name: childrenName[1], fraction: expectedChildShare)]
        
        XCTAssertEqual(expectedClause, AvBoursoLionel!.clause!)
        XCTAssertEqual(missingCapital["M. Arthur MICHAUD"]!, 0.0)
        XCTAssertEqual(missingCapital["Mme. Lou-Ann MICHAUD"]!, 0.0)
    }
    
    func test_modifyLifeInsuranceClauseIfNecessaryAndPossible() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        
        //                      = pris en compte * part héritage * valeur
        let therory_period_tonl_enf = 1.0 * 0.5 * (0.0 + 10_000.0)
        //let therory_period_tonv_enf = 0.0 * 0.0 * (0.0 +  5_000.0)
        
        //                          = pris en compte * UF/NP * part héritage * valeur
        //let theory_free_peal        = 0.0 * 1.0 * ( 23_900.0 + 149_899.0)
        //let theory_free_livAl       = 0.0 * 1.0 * (      0.0 +  23_063.0)
        let theory_free_av_boul_van = 1.0 * 1.0 * 1.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_boul_enf = 1.0 * 0.5 * 0.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_afel_van = 1.0 * 0.5 * 1.0 * (406_533.0 +  96_805.0)
        let theory_free_av_afel_enf = 1.0 * 0.5 * 0.5 * (406_533.0 +  96_805.0)
        //let theory_free_av_afev     = 0.0 * 0.5 * ( 29_000.0 +  31_213.0)
        
        let capitauxTaxables = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                                "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                                "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]
        
        let capitauxReceivedBrut = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van + 2 * theory_free_av_afel_enf,
                                    "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf,
                                    "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf]
        
        let taxeEnfant = max(0.0, (capitauxTaxables["M. Arthur MICHAUD"]! - 0.5 * 152500.0) * 0.2)

        var capitauxDeces = LifeInsuranceSuccessionManager.NameCapitauxDecesDico()
        capitauxDeces["M. Arthur MICHAUD"] =
            LifeInsuranceSuccessionManager
            .CapitauxDeces(received: (brut: capitauxReceivedBrut["Mme. Lou-Ann MICHAUD"]!,
                                      net: capitauxReceivedBrut["M. Arthur MICHAUD"]! - taxeEnfant))
        capitauxDeces["Mme. Lou-Ann MICHAUD"] =
            LifeInsuranceSuccessionManager
            .CapitauxDeces(received: (brut: capitauxReceivedBrut["Mme. Lou-Ann MICHAUD"]!,
                                      net: capitauxReceivedBrut["Mme. Lou-Ann MICHAUD"]! - taxeEnfant))
        
        let taxes = ["M. Arthur MICHAUD"    : taxeEnfant,
                     "Mme. Lou-Ann MICHAUD" : taxeEnfant]
        
        XCTAssertNoThrow(try Tests.manager
            .modifyLifeInsuranceClauseIfNecessaryAndPossible(decedentName          : decedentName,
                                                             conjointName          : spouseName,
                                                             withAssets            : &Tests.patrimoin.assets,
                                                             withLiabilities       : Tests.patrimoin.liabilities,
                                                             toPayFor              : taxes,
                                                             capitauxDecesRecusNet : capitauxDeces,
                                                             verbose               : Tests.verbose))
    }
}
