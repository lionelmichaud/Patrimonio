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

final class LifeInsuranceSuccessionManagerTests: XCTestCase {
    typealias Tests = LifeInsuranceSuccessionManagerTests

    static var manager     : LifeInsuranceSuccessionManager!
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
        
        // charger le patrimoine
        patrimoin = Patrimoin(fromBundle: Bundle.module,
                              fileNamePrefix: "LifeInsMng_")
        
        // charger la famille
        XCTAssertNoThrow(family = try Family(fromBundle: Bundle.module, using: model),
                         "Failed to read Family from Module Bundle \(String(describing: Bundle.module.resourcePath))")
        
        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(family)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(family)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = family
        
        // initialiser le Manager
        manager = LifeInsuranceSuccessionManager(using          : fiscalModel,
                                                 familyProvider : family,
                                                 atEndOf        : 2021)
    }

    // MARK: Tests Calculs Abattements

    func test_calcul_abattementsParPersonne() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        let financialEnvelops: [FinancialEnvelopP] =
            Tests.patrimoin.assets.freeInvests.items + Tests.patrimoin.assets.periodicInvests.items

        let abattementsDico =
        Tests.manager.abattementsParPersonne(of           : decedentName,
                                             with         : financialEnvelops,
                                             spouseName   : spouseName,
                                             childrenName : childrenName,
                                             verbose      : Tests.verbose)
        
        let theory = ["Mme. Vanessa MICHAUD" : 1.0,
                      "M. Arthur MICHAUD"    : 0.5,
                      "Mme. Lou-Ann MICHAUD" : 0.5]

        XCTAssertEqual(theory, abattementsDico)
    }

    func test_calcul_abattementsParCouple() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        let financialEnvelops: [FinancialEnvelopP] =
        Tests.patrimoin.assets.freeInvests.items + Tests.patrimoin.assets.periodicInvests.items

        let abattementsParCouple =
        Tests.manager.abattementsParCouple(of           : decedentName,
                                           with         : financialEnvelops,
                                           spouseName   : spouseName,
                                           childrenName : childrenName,
                                           verbose      : Tests.verbose)

        let theory = LifeInsuranceSuccessionManager.SetAbatCoupleUFNP([
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "M. Arthur MICHAUD",    value: 0.5)),
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "Mme. Lou-Ann MICHAUD", value: 0.5))
        ])

        XCTAssertEqual(theory, abattementsParCouple)
    }

    func test_calcul_abattementsParAssurance() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        let avAfer =
        Tests.patrimoin.assets.freeInvests.items.first(where: { $0.name == "AV Lionel AFER" })!

        let abattementsParAssurance =
        Tests.manager.abattementsParAssurance(of           : decedentName,
                                              spouseName   : spouseName,
                                              childrenName : childrenName,
                                              for          : avAfer,
                                              verbose      : Tests.verbose)
        
        let theory = LifeInsuranceSuccessionManager.SetAbatCoupleUFNP([
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "M. Arthur MICHAUD",    value: 0.5)),
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "Mme. Lou-Ann MICHAUD", value: 0.5))
        ])
        
        XCTAssertEqual(theory, abattementsParAssurance)
    }
}
