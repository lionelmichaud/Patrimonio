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
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        let financialEnvelops: [FinancialEnvelopP] =
            Tests.patrimoin.assets.freeInvests.items + Tests.patrimoin.assets.periodicInvests.items
        
        let abattementsDico =
            Tests.manager.abattementsParPersonne(for          : financialEnvelops,
                                                 spouseName   : spouseName,
                                                 childrenName : childrenName,
                                                 verbose      : Tests.verbose)
        
        let theory = ["Mme. Vanessa MICHAUD" : 1.0,
                      "M. Arthur MICHAUD"    : 0.5,
                      "Mme. Lou-Ann MICHAUD" : 0.5]
        
        XCTAssertEqual(theory, abattementsDico)
    }
    
    func test_calcul_abattementsParCouple() {
        let financialEnvelops: [FinancialEnvelopP] =
            Tests.patrimoin.assets.freeInvests.items + Tests.patrimoin.assets.periodicInvests.items
        
        let abattementsParCouple =
            Tests.manager.abattementsParCouple(for     : financialEnvelops,
                                               verbose : Tests.verbose)
        
        let theory = LifeInsuranceSuccessionManager.SetAbatCoupleUFNP([
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "M. Arthur MICHAUD",    value: 0.5)),
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "Mme. Lou-Ann MICHAUD", value: 0.5))
        ])
        
        XCTAssertEqual(theory, abattementsParCouple)
    }
    
    func test_calcul_abattementsParAssurance() {
        let avAfer =
            Tests.patrimoin.assets.freeInvests.items.first(where: { $0.name == "AV Lionel AFER" })!
        
        let abattementsParAssurance =
            Tests.manager.abattementsParAssurance(for          : avAfer,
                                                  verbose      : Tests.verbose)
        
        let theory = LifeInsuranceSuccessionManager.SetAbatCoupleUFNP([
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "M. Arthur MICHAUD",    value: 0.5)),
            LifeInsuranceSuccessionManager.CoupleUFNP(UF: NamedValue(name: "Mme. Vanessa MICHAUD", value: 0.5),
                                                      NP: NamedValue(name: "Mme. Lou-Ann MICHAUD", value: 0.5))
        ])
        
        XCTAssertEqual(theory, abattementsParAssurance)
    }
    
    // MARK: Tests Calculs Capitaux Décès Taxables et Reçus en Cash
    
    func test_capitauxDecesAvUndismembered() {
        let defunt   = "M. Lionel MICHAUD"
        let conjoint = "Mme. Vanessa MICHAUD"
        let enfant1  = "Mme. Lou-Ann MICHAUD"
        let enfant2  = "M. Arthur MICHAUD"
        
        // Cas n°1: clause non démembrée
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
            .capitauxDecesAvUndismembered(of           : defunt,
                                          for          : invest,
                                          verbose      : Tests.verbose)
        var theoryTaxable = [enfant1 : 40.0,
                             enfant2 : 60.0]
        var theoryReceived = [enfant1 : 40.0,
                              enfant2 : 60.0]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        
        // Cas n°2: clause non démembrée
        ownership.fullOwners = [Owner(name: defunt,   fraction: 50.0),
                                Owner(name: conjoint, fraction: 50.0)]
        invest.ownership = ownership
        
        capitalDeces = Tests.manager
            .capitauxDecesAvUndismembered(of           : defunt,
                                          for          : invest,
                                          verbose      : Tests.verbose)
        theoryTaxable = [enfant1 : 0.4 * 50.0,
                         enfant2 : 0.6 * 50.0]
        theoryReceived = [enfant1 : 0.4 * 50.0,
                          enfant2 : 0.6 * 50.0]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        
        // cas n°3: clause non démembrée
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
            .capitauxDecesAvUndismembered(of           : defunt,
                                          for          : invest,
                                          verbose      : Tests.verbose)
        theoryTaxable = [enfant1  : 20.0 + 0.4 * 50.0 - 20.0,
                         enfant2  : 30.0 + 0.6 * 50.0 - 30.0]
        theoryReceived = [enfant1  : 20.0 + 0.4 * 50.0 - 20.0,
                          enfant2  : 30.0 + 0.6 * 50.0 - 30.0]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        
        // cas n°4: clause démembrée
        ownership.fullOwners = [Owner(name: defunt, fraction: 100.0)]
        invest.ownership = ownership
        
        clause.isDismembered     = true
        clause.usufructRecipient = conjoint
        clause.bareRecipients    = [enfant1, enfant2]
        type = InvestementKind.lifeInsurance(periodicSocialTaxes: true,
                                             clause: clause)
        invest.type = type
        
        capitalDeces = Tests.manager
            .capitauxDecesAvUndismembered(of           : defunt,
                                          for          : invest,
                                          verbose      : Tests.verbose)
        theoryTaxable = [conjoint : 50.0,
                         enfant1  : 0.5 * 50.0,
                         enfant2  : 0.5 * 50.0]
        theoryReceived = [conjoint : 100.0]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        
        // cas n°5: clause démembrée
        ownership.fullOwners = [Owner(name: defunt,  fraction: 50.0),
                                Owner(name: enfant1, fraction: 20.0),
                                Owner(name: enfant2, fraction: 30.0)]
        invest.ownership = ownership
        
        clause.isDismembered     = true
        clause.usufructRecipient = conjoint
        clause.bareRecipients    = [enfant1, enfant2]
        type = InvestementKind.lifeInsurance(periodicSocialTaxes: true,
                                             clause: clause)
        invest.type = type
        
        capitalDeces = Tests.manager
            .capitauxDecesAvUndismembered(of           : defunt,
                                          for          : invest,
                                          verbose      : Tests.verbose)
        theoryTaxable = [conjoint : 0.5 * 50.0,
                         enfant1  : 0.5/2.0 * 50.0,
                         enfant2  : 0.5/2.0 * 50.0]
        theoryReceived = [conjoint : 50.0]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
    }
    
    func test_capitauxDecesAvDismembered() {
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
            .capitauxDecesAvDismembered(of      : defunt,
                                        for     : invest,
                                        verbose : Tests.verbose)
        
        var theoryTaxable : NameValueDico = [:]
        var theoryReceived: NameValueDico = [:]
        var theoryCreances: CreanceDeRestituationDico = [:]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        XCTAssertEqual(theoryCreances, capitalDeces.creances)
        
        // cas n°2
        ownership.usufructOwners = [Owner(name: conjoint, fraction: 100.0)]
        invest.ownership = ownership
        
        capitalDeces = Tests.manager
            .capitauxDecesAvDismembered(of      : defunt,
                                        for     : invest,
                                        verbose : Tests.verbose)
        
        theoryTaxable  = [:]
        theoryReceived = [:]
        theoryCreances = [:]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        XCTAssertEqual(theoryCreances, capitalDeces.creances)
        
        // cas n°3
        invest.type = .pea
        
        capitalDeces = Tests.manager
            .capitauxDecesAvDismembered(of      : defunt,
                                        for     : invest,
                                        verbose : Tests.verbose)
        
        theoryTaxable  = [:]
        theoryReceived = [:]
        theoryCreances = [:]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        XCTAssertEqual(theoryCreances, capitalDeces.creances)
        
        // cas n°4
        invest.type = .other
        
        capitalDeces = Tests.manager
            .capitauxDecesAvDismembered(of      : defunt,
                                        for     : invest,
                                        verbose : Tests.verbose)
        
        theoryTaxable  = [:]
        theoryReceived = [:]
        theoryCreances = [:]
        
        XCTAssertEqual(theoryTaxable, capitalDeces.taxable)
        XCTAssertEqual(theoryReceived, capitalDeces.received)
        XCTAssertEqual(theoryCreances, capitalDeces.creances)
    }
    
    func test_capitauxDecesTaxableRecusParPersonne() {
        let decedentName = "M. Lionel MICHAUD"
        
        let financialEnvelops: [FinancialEnvelopP] =
            Tests.patrimoin.assets.freeInvests.items + Tests.patrimoin.assets.periodicInvests.items
        
        let capitauxDecesParPersonne =
            Tests.manager.capitauxDecesTaxableRecusParPersonne(of           : decedentName,
                                                               with         : financialEnvelops,
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
        
        let theoryTaxable = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                             "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                             "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]
        
        let theoryReceived = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van + 2 * theory_free_av_afel_enf,
                              "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf,
                              "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf]
        
        let theoryCreances: CreanceDeRestituationDico =
            ["Mme. Vanessa MICHAUD" : ["M. Arthur MICHAUD"    : (theory_free_av_afel_van + 2 * theory_free_av_afel_enf) / 2.0,
                                       "Mme. Lou-Ann MICHAUD" : (theory_free_av_afel_van + 2 * theory_free_av_afel_enf) / 2.0]
            ]
        
        XCTAssertEqual(theoryTaxable, capitauxDecesParPersonne.taxable)
        XCTAssertEqual(theoryReceived, capitauxDecesParPersonne.received)
        XCTAssertEqual(theoryCreances, capitauxDecesParPersonne.creances)
    }
    
    // MARK: Tests Calcul Succession Assurances Vies
    
    func test_succession() {
        let decedentName = "M. Lionel MICHAUD"
        let spouseName   = "Mme. Vanessa MICHAUD"
        let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
        
        let succession = Tests.manager.succession(of           : decedentName,
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
        
        let capitauxTaxables = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                                "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                                "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]
        
        let capitauxReceived = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van + 2 * theory_free_av_afel_enf,
                                "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf,
                                "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf]
        
        let theoryCreances: CreanceDeRestituationDico =
            ["Mme. Vanessa MICHAUD" : ["M. Arthur MICHAUD"    : (theory_free_av_afel_van + 2 * theory_free_av_afel_enf) / 2.0,
                                       "Mme. Lou-Ann MICHAUD" : (theory_free_av_afel_van + 2 * theory_free_av_afel_enf) / 2.0]
            ]
        
        let taxeEnfant = (capitauxTaxables["M. Arthur MICHAUD"]! - 0.5 * 152500.0) * 0.2
        
        let capitauxDeces: LifeInsuranceSuccessionManager.NameCapitauxDecesDico =
            ["Mme. Vanessa MICHAUD" : LifeInsuranceSuccessionManager.CapitauxDeces(fiscal  : (brut: capitauxTaxables["Mme. Vanessa MICHAUD"]!,
                                                                                              net : capitauxTaxables["Mme. Vanessa MICHAUD"]!),
                                                                                   received: (brut: capitauxReceived["Mme. Vanessa MICHAUD"]!,
                                                                                              net : capitauxReceived["Mme. Vanessa MICHAUD"]!),
                                                                                   creance : 0.0),
             "M. Arthur MICHAUD"    : LifeInsuranceSuccessionManager.CapitauxDeces(fiscal  : (brut: capitauxTaxables["M. Arthur MICHAUD"]!,
                                                                                              net : capitauxTaxables["M. Arthur MICHAUD"]! - taxeEnfant),
                                                                                   received: (brut: capitauxReceived["M. Arthur MICHAUD"]!,
                                                                                              net:  capitauxReceived["M. Arthur MICHAUD"]! - taxeEnfant),
                                                                                   creance: theoryCreances["Mme. Vanessa MICHAUD"]!["M. Arthur MICHAUD"]!),
             "Mme. Lou-Ann MICHAUD" : LifeInsuranceSuccessionManager.CapitauxDeces(fiscal  : (brut: capitauxTaxables["Mme. Lou-Ann MICHAUD"]!,
                                                                                              net : capitauxTaxables["Mme. Lou-Ann MICHAUD"]! - taxeEnfant),
                                                                                   received: (brut: capitauxReceived["Mme. Lou-Ann MICHAUD"]!,
                                                                                              net : capitauxReceived["Mme. Lou-Ann MICHAUD"]! - taxeEnfant),
                                                                                   creance: theoryCreances["Mme. Vanessa MICHAUD"]!["Mme. Lou-Ann MICHAUD"]!)]
        
        let inheritances = [
            Inheritance(personName    : "Mme. Vanessa MICHAUD",
                        percentFiscal : capitauxTaxables["Mme. Vanessa MICHAUD"]! / totalTaxableInheritanceValue,
                        brutFiscal    : capitauxTaxables["Mme. Vanessa MICHAUD"]!,
                        abatFrac      : 1.0,
                        netFiscal     : capitauxTaxables["Mme. Vanessa MICHAUD"]!,
                        tax           : 0.0,
                        received      : capitauxReceived["Mme. Vanessa MICHAUD"]!,
                        receivedNet   : capitauxReceived["Mme. Vanessa MICHAUD"]!,
                        creanceRestit : 0.0),
            Inheritance(personName    : "M. Arthur MICHAUD",
                        percentFiscal : capitauxTaxables["M. Arthur MICHAUD"]! / totalTaxableInheritanceValue,
                        brutFiscal    : capitauxTaxables["M. Arthur MICHAUD"]!,
                        abatFrac      : 0.5,
                        netFiscal     : capitauxTaxables["M. Arthur MICHAUD"]! - taxeEnfant,
                        tax           : taxeEnfant,
                        received      : capitauxReceived["M. Arthur MICHAUD"]!,
                        receivedNet   : capitauxReceived["M. Arthur MICHAUD"]! - taxeEnfant,
                        creanceRestit : theoryCreances["Mme. Vanessa MICHAUD"]!["M. Arthur MICHAUD"]!),
            Inheritance(personName    : "Mme. Lou-Ann MICHAUD",
                        percentFiscal : capitauxTaxables["Mme. Lou-Ann MICHAUD"]! / totalTaxableInheritanceValue,
                        brutFiscal    : capitauxTaxables["Mme. Lou-Ann MICHAUD"]!,
                        abatFrac      : 0.5,
                        netFiscal     : capitauxTaxables["Mme. Lou-Ann MICHAUD"]! - taxeEnfant,
                        tax           : taxeEnfant,
                        received      : capitauxReceived["Mme. Lou-Ann MICHAUD"]!,
                        receivedNet   : capitauxReceived["Mme. Lou-Ann MICHAUD"]! - taxeEnfant,
                        creanceRestit : theoryCreances["Mme. Vanessa MICHAUD"]!["Mme. Lou-Ann MICHAUD"]!)
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
        XCTAssertEqual(theoryCreances, Tests.manager.creanceDeRestituationDico)
        XCTAssertEqual(capitauxDeces, Tests.manager.capitauxDeces)
    }
}
