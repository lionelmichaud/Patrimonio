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

final class LifeInsSuccessionManagerTests: XCTestCase {
    typealias Tests = LifeInsSuccessionManagerTests
    
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
        
        // charger la famille
        XCTAssertNoThrow(family = try Family(fromBundle: Bundle.module, using: model),
                         "Failed to read Family from Module Bundle \(String(describing: Bundle.module.resourcePath))")
        
        // charger le patrimoine
        // injection de family dans la propriété statique de Patrimoin
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
    
    // MARK: Tests Calculs Capituax Décès Taxables
    
    func test_undismemberedLifeInsCapitauxDecesTaxables() {
        let defunt   = "M. Lionel MICHAUD"
        let conjoint = "Mme. Vanessa MICHAUD"
        let enfant1  = "Mme. Lou-Ann MICHAUD"
        let enfant2  = "M. Arthur MICHAUD"
        
        // Cas n°1
        var ownership = Ownership(ageOf: Tests.family.ageOf)
        ownership.isDismembered = false
        ownership.fullOwners = [Owner(name: defunt, fraction: 100.0)]
        
        var clause = LifeInsuranceClause()
        clause.isOptional     = false
        clause.isDismembered  = false
        clause.fullRecipients = [Owner(name: enfant1, fraction: 40.0),
                                 Owner(name: enfant2, fraction: 60.0)]
        var type = InvestementKind.lifeInsurance(periodicSocialTaxes: true,
                                                 clause: clause)
        
        var invest = FreeInvestement(year            : 2020,
                                     name            : "Assurance Vie",
                                     note            : "note",
                                     type            : type,
                                     interestRateType: InterestRateKind.contractualRate(fixedRate: 0.0),
                                     initialValue    : 100,
                                     initialInterest : 0)
        invest.ownership = ownership
        
        var capitalDeces = Tests.manager
            .undismemberedLifeInsCapitauxDecesTaxables(of           : defunt,
                                                       spouseName   : conjoint,
                                                       childrenName : [enfant1, enfant2],
                                                       for          : invest,
                                                       verbose      : Tests.verbose)
        var theory = [enfant1 : 40.0,
                      enfant2 : 60.0]
        
        XCTAssertEqual(theory, capitalDeces)
        
        // Cas n°2
        ownership.fullOwners = [Owner(name: defunt,   fraction: 50.0),
                                Owner(name: conjoint, fraction: 50.0)]
        invest.ownership = ownership
        
        capitalDeces = Tests.manager
            .undismemberedLifeInsCapitauxDecesTaxables(of           : defunt,
                                                       spouseName   : conjoint,
                                                       childrenName : [enfant1, enfant2],
                                                       for          : invest,
                                                       verbose      : Tests.verbose)
        theory = [enfant1 : 0.4 * 50.0,
                  enfant2 : 0.6 * 50.0]
        
        XCTAssertEqual(theory, capitalDeces)
        
        // Cas n°3
        ownership.fullOwners = [Owner(name: defunt,   fraction: 50.0),
                                Owner(name: conjoint, fraction: 50.0)]
        invest.ownership = ownership
        
        capitalDeces = Tests.manager
            .undismemberedLifeInsCapitauxDecesTaxables(of           : defunt,
                                                       spouseName   : conjoint,
                                                       childrenName : [enfant1, enfant2],
                                                       for          : invest,
                                                       verbose      : Tests.verbose)
        theory = [enfant1 : 0.4 * 50.0,
                  enfant2 : 0.6 * 50.0]
        
        XCTAssertEqual(theory, capitalDeces)
        
        // cas n°3
        ownership.fullOwners = [Owner(name: defunt, fraction: 100.0)]
        invest.ownership = ownership
        
        clause.isDismembered     = true
        clause.usufructRecipient = conjoint
        clause.bareRecipients    = [enfant1, enfant2]
        type = InvestementKind.lifeInsurance(periodicSocialTaxes: true,
                                             clause: clause)
        invest.type = type
        
        capitalDeces = Tests.manager
            .undismemberedLifeInsCapitauxDecesTaxables(of           : defunt,
                                                       spouseName   : conjoint,
                                                       childrenName : [enfant1, enfant2],
                                                       for          : invest,
                                                       verbose      : Tests.verbose)
        theory = [conjoint : 50.0,
                  enfant1  : 0.5 * 50.0,
                  enfant2  : 0.5 * 50.0]
        
        XCTAssertEqual(theory, capitalDeces)
        
        // cas n°4
        ownership.fullOwners = [Owner(name: defunt,  fraction: 50.0),
                                Owner(name: enfant1, fraction: 20.0),
                                Owner(name: enfant2, fraction: 30.0)]
        invest.ownership = ownership
        
        clause.isDismembered  = false
        clause.fullRecipients = [Owner(name: enfant1, fraction: 40.0),
                                 Owner(name: enfant2, fraction: 60.0)]
        type = InvestementKind.lifeInsurance(periodicSocialTaxes: true,
                                             clause: clause)
        invest.type = type
        
        capitalDeces = Tests.manager
            .undismemberedLifeInsCapitauxDecesTaxables(of           : defunt,
                                                       spouseName   : conjoint,
                                                       childrenName : [enfant1, enfant2],
                                                       for          : invest,
                                                       verbose      : Tests.verbose)
        theory = [enfant1  : 20.0 + 0.4 * 50.0 - 20.0,
                  enfant2  : 30.0 + 0.6 * 50.0 - 30.0]
        
        XCTAssertEqual(theory, capitalDeces)
    }
    
    func test_dismemberedLifeInsCapitauxDecesTaxables() {
        let defunt   = "M. Lionel MICHAUD"
        let conjoint = "Mme. Vanessa MICHAUD"
        let enfant1  = "Mme. Lou-Ann MICHAUD"
        let enfant2  = "M. Arthur MICHAUD"
        
        // cas n°1
        var ownership = Ownership(ageOf: Tests.family.ageOf)
        ownership.isDismembered = true
        ownership.usufructOwners = [Owner(name: defunt, fraction: 100.0)]
        ownership.bareOwners = [Owner(name: enfant1, fraction: 40.0),
                                Owner(name: enfant2, fraction: 60.0)]
        
        var clause = LifeInsuranceClause()
        clause.isOptional     = false
        clause.isDismembered  = false
        clause.fullRecipients = [Owner(name: enfant1, fraction: 40.0),
                                 Owner(name: enfant2, fraction: 60.0)]
        let type = InvestementKind.lifeInsurance(periodicSocialTaxes: true,
                                                 clause: clause)
        
        var invest = FreeInvestement(year            : 2020,
                                     name            : "Assurance Vie",
                                     note            : "note",
                                     type            : type,
                                     interestRateType: InterestRateKind.contractualRate(fixedRate: 0.0),
                                     initialValue    : 100,
                                     initialInterest : 0)
        invest.ownership = ownership
        
        var capitalDeces = Tests.manager
            .dismemberedLifeInsCapitauxDecesTaxables(of        : defunt,
                                                     for     : invest,
                                                     verbose : Tests.verbose)
        
        var theory: NameValueDico = [:]
        
        XCTAssertEqual(theory, capitalDeces)
        
        // cas n°2
        ownership.usufructOwners = [Owner(name: conjoint, fraction: 100.0)]
        invest.ownership = ownership
        
        capitalDeces = Tests.manager
            .dismemberedLifeInsCapitauxDecesTaxables(of        : defunt,
                                                     for     : invest,
                                                     verbose : Tests.verbose)
        
        theory = [:]
        
        XCTAssertEqual(theory, capitalDeces)
    }
    
    func test_capitauxDecesTaxablesParPersonne() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        
        let financialEnvelops: [FinancialEnvelopP] =
            Tests.patrimoin.assets.freeInvests.items + Tests.patrimoin.assets.periodicInvests.items
        
        let capitauxDecesParPersonne =
            Tests.manager.capitauxDecesTaxablesParPersonne(of           : decedentName,
                                                           with         : financialEnvelops,
                                                           spouseName   : spouseName,
                                                           childrenName : childrenName,
                                                           verbose      : Tests.verbose)
        
        //                      = pris en compte * part héritage * valeur
        let therory_period_tonl_enf = 1.0 * 0.5 * (0.0 + 150_000.0)
        //let therory_period_tonv_enf = 0.0 * 0.0 * (0.0 +  5_000.0)
        
        //                          = pris en compte * UF/NP * part héritage * valeur
        //let theory_free_peal        = 0.0 * 1.0 * ( 23_900.0 + 149_899.0)
        //let theory_free_livAl       = 0.0 * 1.0 * (      0.0 +  23_063.0)
        let theory_free_av_boul_van = 1.0 * 1.0 * 1.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_boul_enf = 1.0 * 0.5 * 0.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_afel_van = 1.0 * 0.5 * 1.0 * (106_533.0 +  96_805.0)
        let theory_free_av_afel_enf = 1.0 * 0.5 * 0.5 * (106_533.0 +  96_805.0)
        //let theory_free_av_afev     = 0.0 * 0.5 * ( 29_000.0 +  31_213.0)
        
        let theory = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                      "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                      "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]
        
        XCTAssertEqual(theory, capitauxDecesParPersonne)
    }
    
    // MARK: Tests Calcul Succession Assurances Vies
    
    func test_lifeInsuranceSuccession() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        
        let succession = Tests.manager.fiscalSuccession(of           : decedentName,
                                                               with         : Tests.patrimoin,
                                                               spouseName   : spouseName,
                                                               childrenName : childrenName,
                                                               verbose      : Tests.verbose)
        
        //                      = pris en compte * part héritage * valeur
        let therory_period_tonl_enf = 1.0 * 0.5 * (0.0 + 150_000.0)
        //let therory_period_tonv_enf = 0.0 * 0.0 * (0.0 +  5_000.0)
        
        //                          = pris en compte * UF/NP * part héritage * valeur
        //let theory_free_peal        = 0.0 * 1.0 * ( 23_900.0 + 149_899.0)
        //let theory_free_livAl       = 0.0 * 1.0 * (      0.0 +  23_063.0)
        let theory_free_av_boul_van = 1.0 * 1.0 * 1.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_boul_enf = 1.0 * 0.5 * 0.0 * (  2_621.0 + 104_594.0)
        let theory_free_av_afel_van = 1.0 * 0.5 * 1.0 * (106_533.0 +  96_805.0)
        let theory_free_av_afel_enf = 1.0 * 0.5 * 0.5 * (106_533.0 +  96_805.0)
        //let theory_free_av_afev     = 0.0 * 0.5 * ( 29_000.0 +  31_213.0)
        
        let totalTaxableInheritanceValue =
            2.0 * (therory_period_tonl_enf + theory_free_av_afel_enf + theory_free_av_boul_enf) +
            theory_free_av_afel_van + theory_free_av_boul_van
        
        let capitauxDeces = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                             "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                             "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]
        
        let taxeEnfant = (capitauxDeces["M. Arthur MICHAUD"]! - 0.5 * 152500.0) * 0.2
        
        let inheritances = [
            Inheritance(personName : "Mme. Vanessa MICHAUD",
                        percent    : capitauxDeces["Mme. Vanessa MICHAUD"]! / totalTaxableInheritanceValue,
                        brut       : capitauxDeces["Mme. Vanessa MICHAUD"]!,
                        abatFrac   : 1.0,
                        net        : capitauxDeces["Mme. Vanessa MICHAUD"]!,
                        tax        : 0.0),
            Inheritance(personName : "M. Arthur MICHAUD",
                        percent    : capitauxDeces["M. Arthur MICHAUD"]! / totalTaxableInheritanceValue,
                        brut       : capitauxDeces["M. Arthur MICHAUD"]!,
                        abatFrac   : 0.5,
                        net        : capitauxDeces["M. Arthur MICHAUD"]! - taxeEnfant,
                        tax        : taxeEnfant),
            Inheritance(personName : "Mme. Lou-Ann MICHAUD",
                        percent    : capitauxDeces["Mme. Lou-Ann MICHAUD"]! / totalTaxableInheritanceValue,
                        brut       : capitauxDeces["Mme. Lou-Ann MICHAUD"]!,
                        abatFrac   : 0.5,
                        net        : capitauxDeces["Mme. Lou-Ann MICHAUD"]! - taxeEnfant,
                        tax        : taxeEnfant)
        ]
        
        let theory = Succession(kind         : .lifeInsurance,
                                yearOfDeath  : 2021,
                                decedentName : decedentName,
                                taxableValue : totalTaxableInheritanceValue,
                                inheritances : inheritances)
        
        XCTAssertEqual(theory.kind, succession.kind)
        XCTAssertEqual(theory.decedentName, succession.decedentName)
        XCTAssertEqual(theory.taxableValue, succession.taxableValue)
        XCTAssertTrue(theory.inheritances.containsSameElements(as: succession.inheritances))
    }
}
