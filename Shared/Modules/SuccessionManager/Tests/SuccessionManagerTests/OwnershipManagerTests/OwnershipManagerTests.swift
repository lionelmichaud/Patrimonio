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
    
    func test_childrenNetSellableAssets() {
        let sellableAssets =
            Tests.manager.childrenNetSellableAssets(withAssets      : Tests.patrimoin.assets,
                                                    withLiabilities : Tests.patrimoin.liabilities)
        
        let theory = ["M. Arthur MICHAUD"    : 0.0,
                      "Mme. Lou-Ann MICHAUD" : 0.0]
        XCTAssertEqual(theory, sellableAssets)
    }
    
    func test_childrenSellableCapitalAfterInheritance() {
        let decedentName = "M. Lionel MICHAUD"
        let sellableAssets =
            Tests.manager.childrenSellableCapitalAfterInheritance(receivedFrom    : decedentName,
                                                                  withAssets      : Tests.patrimoin.assets,
                                                                  withLiabilities : Tests.patrimoin.liabilities)
        
    }
    
    func test_missingCapital() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["Mme. Isaline MICHAUD", "M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        
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
        
        let sellableAssets =
            Tests.manager.missingCapital(decedentName          : decedentName,
                                         withAssets            : Tests.patrimoin.assets,
                                         withLiabilities       : Tests.patrimoin.liabilities,
                                         toPayFor              : taxes,
                                         capitauxDecesRecusNet : capitauxDeces,
                                         verbose               : Tests.verbose)
        
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
