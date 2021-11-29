import XCTest
@testable import SuccessionManager
import Succession
import ModelEnvironment
import FiscalModel
import PersonModel
import DateBoundary
import FamilyModel
import AssetsModel
import Ownership
import PatrimoineModel

func isApproximatelyEqual(_ x: Double, _ y: Double) -> Bool {
    if x == 0 {
        return abs((x-y)) < 0.0001
    } else {
        return abs((x-y)) / x < 0.0001
    }
}

final class LegalSuccessionManagerTests: XCTestCase {
    typealias Tests = LegalSuccessionManagerTests
    
    static var manager     : LegalSuccessionManager!
    static var model       : Model!
    static var fiscalModel : Fiscal.Model!
    static var family      : Family!
    static var patrimoin   : Patrimoin!
    
    static let verbose = false
    
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
        Patrimoin.familyProvider = family
        patrimoin = Patrimoin(fromBundle: Bundle.module,
                              fileNamePrefix: "LifeInsMng_")
        
        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(family)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(family)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = family
        
        // initialiser le Manager
        manager = LegalSuccessionManager(using          : fiscalModel,
                                         familyProvider : family,
                                         atEndOf        : 2021)
    }
    
    override func setUp() {
        // charger la famille
        XCTAssertNoThrow(Tests.family = try Family(fromBundle: Bundle.module, using: Tests.model),
                         "Failed to read Family from Module Bundle \(String(describing: Bundle.module.resourcePath))")
        
        // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
        DateBoundary.setPersonEventYearProvider(Tests.family)
        // injection de family dans la propriété statique de Adult
        Adult.setAdultRelativesProvider(Tests.family)
        // injection de family dans la propriété statique de Patrimoin
        Patrimoin.familyProvider = Tests.family
        
        // initialiser le Manager
        Tests.manager = LegalSuccessionManager(using          : Tests.fiscalModel,
                                               familyProvider : Tests.family,
                                               atEndOf        : 2021)
    }
    
    // MARK: Tests
    
    func test_masseSuccessorale_lionel() {
        let masse = Tests.manager.masseSuccessorale(in      : Tests.patrimoin,
                                                    of      : "M. Lionel MICHAUD",
                                                    verbose : Tests.verbose)
        
        let theory_debt = 0.7 * 16_000.0
        let theory_loan = 0.5 *  5_894.0
        
        //                      = pris en compte * droit de prop * valeur
        let therory_period_tonl = 0.0 * 1.0 * (0.0 + 27_321.0)
        let therory_period_tonv = 0.0 * 0.0 * (0.0 +  5_000.0)
        
        //                      = pris en compte * droit de prop * valeur
        let theory_free_peal    = 1.0 * 1.0 * ( 23_900.0 + 149_899.0)
        let theory_free_av_boul = 0.0 * 1.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_afel = 0.0 * 1.0 * (106_533.0 +  96_805.0)
        let theory_free_av_afev = 0.0 * 0.0 * ( 29_000.0 +  31_213.0)
        let theory_free_livAl   = 1.0 * 1.0 * (      0.0 +  23_063.0)
        
        let theory_real     = 0.7 * 600_000.0 * (1.0 - 0.2) // décote de 20%
        let theory_scpi     = 1.0 *  11_000.0 * (1.0 - 0.1) // 10% de frais
        let theory_sci_scpi = 0.9 *  72_365.0 * (1.0 - 0.1) // 10% de frais
        
        let total_free = (theory_free_peal + theory_free_av_boul + theory_free_av_afel + theory_free_av_afev + theory_free_livAl)
        let total_period = (therory_period_tonl + therory_period_tonv)
        let theory =
        (total_free + total_period + theory_real + theory_scpi + theory_sci_scpi)
        - (theory_debt + theory_loan)
        
        XCTAssertTrue(isApproximatelyEqual(masse, theory))
    }
    
    func test_childrenInheritance() throws {
        let masse = 400_000.0
        let share = 0.5
        
        let inheritance = Tests.manager
            .childrenInheritance(inheritanceShareForChild : share,
                                 masseSuccessorale        : masse,
                                 verbose                  : Tests.verbose)
        
        let brut = masse * share
        var heritageOfChild: (netAmount: Double, taxe: Double) = (0.0, 0.0)
        XCTAssertNoThrow(heritageOfChild = try Tests.fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brut),
                         "failed in fiscalModel.inheritanceDonation.heritageOfChild")
        let theoryInheritance = Set([Inheritance(personName    : "M. Arthur MICHAUD",
                                                 percentFiscal : share,
                                                 brutFiscal    : brut,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe),
                                     Inheritance(personName    : "Mme. Lou-Ann MICHAUD",
                                                 percentFiscal : share,
                                                 brutFiscal    : brut,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe)])
        
        XCTAssertEqual(Set(inheritance), theoryInheritance)
    }
    
    func test_spouseInheritance() {
        let masse         = 400_000.0
        let conjointShare = 0.5
        let childShare    = 0.25

        let conjointSurvivant = Tests.family.adults.first(where: { $0.displayName == "Mme. Vanessa MICHAUD" })!
        let inheritance = Tests.manager
            .spouseAndChildrenInheritance(masseSuccessorale : masse,
                               conjointSurvivant : conjointSurvivant)
        
        let brutChild = masse * childShare
        var heritageOfChild: (netAmount: Double, taxe: Double) = (0.0, 0.0)
        XCTAssertNoThrow(heritageOfChild = try Tests.fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brutChild),
                         "failed in fiscalModel.inheritanceDonation.heritageOfChild")
        let theoryInheritance = Set([Inheritance(personName    : "Mme. Vanessa MICHAUD",
                                                 percentFiscal : conjointShare,
                                                 brutFiscal    : conjointShare * masse,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : conjointShare * masse,
                                                 tax           : 0.0,
                                                 received      : 0.0,
                                                 receivedNet   : 0.0),
                                     Inheritance(personName    : "M. Arthur MICHAUD",
                                                 percentFiscal : childShare,
                                                 brutFiscal    : brutChild,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe),
                                     Inheritance(personName    : "Mme. Lou-Ann MICHAUD",
                                                 percentFiscal : childShare,
                                                 brutFiscal    : brutChild,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe)])
        
        XCTAssertEqual(Set(inheritance), theoryInheritance)
    }
    
    func test_legalSuccession_avec_conjoint_survivant() {
        let succession = Tests.manager
            .succession(of      : "M. Lionel MICHAUD",
                             with    : Tests.patrimoin,
                             verbose : Tests.verbose)
        
        let masse = Tests.manager.masseSuccessorale(in      : Tests.patrimoin,
                                                    of      : "M. Lionel MICHAUD",
                                                    verbose : Tests.verbose)
        let conjointShare = 0.5
        let childShare    = 0.25
        let brutChild = masse * childShare
        var heritageOfChild: (netAmount: Double, taxe: Double) = (0.0, 0.0)
        XCTAssertNoThrow(heritageOfChild = try Tests.fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brutChild),
                         "failed in fiscalModel.inheritanceDonation.heritageOfChild")
        let theoryInheritance = Set([Inheritance(personName    : "Mme. Vanessa MICHAUD",
                                                 percentFiscal : conjointShare,
                                                 brutFiscal    : conjointShare * masse,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : conjointShare * masse,
                                                 tax           : 0.0,
                                                 received      : 0.0,
                                                 receivedNet   : 0.0),
                                     Inheritance(personName    : "M. Arthur MICHAUD",
                                                 percentFiscal : childShare,
                                                 brutFiscal    : brutChild,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe),
                                     Inheritance(personName    : "Mme. Lou-Ann MICHAUD",
                                                 percentFiscal : childShare,
                                                 brutFiscal    : brutChild,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe)])
        
        XCTAssertEqual(succession.kind, SuccessionKindEnum.legal)
        XCTAssertEqual(succession.yearOfDeath, 2021)
        XCTAssertEqual(succession.decedentName, "M. Lionel MICHAUD")
        XCTAssertEqual(succession.taxableValue, masse)
        XCTAssertEqual(Set(succession.inheritances), theoryInheritance)
    }
    
    func test_legalSuccession_sans_conjoint_survivant() {
        let idx = Tests.family.members.items.firstIndex(where: { $0.displayName == "Mme. Vanessa MICHAUD" })!
        Tests.family.deleteMembers(at: [idx])

        let succession =
        Tests.manager
            .succession(of      : "M. Lionel MICHAUD",
                             with    : Tests.patrimoin,
                             verbose : Tests.verbose)

        let masse = Tests.manager.masseSuccessorale(in      : Tests.patrimoin,
                                                    of      : "M. Lionel MICHAUD",
                                                    verbose : Tests.verbose)

        let childShare = 0.5
        let brutChild  = masse * childShare
        var heritageOfChild: (netAmount: Double, taxe: Double) = (0.0, 0.0)
        XCTAssertNoThrow(heritageOfChild = try Tests.fiscalModel.inheritanceDonation.heritageOfChild(partSuccession: brutChild),
                         "failed in fiscalModel.inheritanceDonation.heritageOfChild")
        let theoryInheritance = Set([Inheritance(personName    : "M. Arthur MICHAUD",
                                                 percentFiscal : childShare,
                                                 brutFiscal    : brutChild,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe),
                                     Inheritance(personName    : "Mme. Lou-Ann MICHAUD",
                                                 percentFiscal : childShare,
                                                 brutFiscal    : brutChild,
                                                 abatFrac      : 1.0,
                                                 netFiscal     : heritageOfChild.netAmount,
                                                 tax           : heritageOfChild.taxe,
                                                 received      : 0.0,
                                                 receivedNet   : -heritageOfChild.taxe)])

        XCTAssertEqual(succession.kind, SuccessionKindEnum.legal)
        XCTAssertEqual(succession.yearOfDeath, 2021)
        XCTAssertEqual(succession.decedentName, "M. Lionel MICHAUD")
        XCTAssertEqual(succession.taxableValue, masse)
        XCTAssertEqual(Set(succession.inheritances), theoryInheritance)
    }
}
