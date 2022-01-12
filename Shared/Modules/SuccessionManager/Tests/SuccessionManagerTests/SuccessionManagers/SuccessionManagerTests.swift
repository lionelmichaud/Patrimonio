import XCTest
@testable import SuccessionManager
import FiscalModel
import ModelEnvironment
import DateBoundary
import Succession
import PersonModel
import FamilyModel
import Ownership
import AssetsModel
import PatrimoineModel
import NamedValue

    final class SuccessionManagerTests: XCTestCase {
        typealias Tests = SuccessionManagerTests
        
        static var manager     : SuccessionManager!
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
            manager = SuccessionManager(with           : patrimoin,
                                        using          : fiscalModel,
                                        atEndOf        : 2021,
                                        familyProvider : family,
                                        run            : 1)
        }
        
        // MARK: Tests Calculs Abattements
        
        func test_computeCashAndTaxesPerPerson() {
            let decedentName = "M. Lionel MICHAUD"
            let spouseName   = "Mme. Vanessa MICHAUD"
            let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
            
            // créer les managers
//            let legalSuccessionManager =
//                LegalSuccessionManager(using          : Tests.fiscalModel,
//                                       familyProvider : Tests.family,
//                                       atEndOf        : 2021)
            var lifeInsuranceSuccessionManager =
                LifeInsuranceSuccessionManager(using          : Tests.fiscalModel,
                                               familyProvider : Tests.family,
                                               atEndOf        : 2021)
            
            // calculers les succession (testées de par ailleurs)
            let lifeInsSuccession =
                lifeInsuranceSuccessionManager.succession(
                    of           : decedentName,
                    with         : Tests.patrimoin,
                    spouseName   : spouseName,
                    childrenName : Tests.family.childrenAliveName(atEndOf : 2021),
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
            
            let capitauxDeces = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                                 "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                                 "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]
            
            let taxeEnfant = (capitauxDeces["M. Arthur MICHAUD"]! - 0.5 * 152500.0) * 0.2
            //
            //            let legalInheritances: [Inheritance] = []
            //
            //            let lifeInsInheritances = [
            //                Inheritance(personName : "Mme. Vanessa MICHAUD",
            //                            percent    : capitauxDeces["Mme. Vanessa MICHAUD"]! / totalTaxableInheritanceValue,
            //                            brut       : capitauxDeces["Mme. Vanessa MICHAUD"]!,
            //                            abatFrac   : 1.0,
            //                            net        : capitauxDeces["Mme. Vanessa MICHAUD"]!,
            //                            tax        : 0.0),
            //                Inheritance(personName : "M. Arthur MICHAUD",
            //                            percent    : capitauxDeces["M. Arthur MICHAUD"]! / totalTaxableInheritanceValue,
            //                            brut       : capitauxDeces["M. Arthur MICHAUD"]!,
            //                            abatFrac   : 0.5,
            //                            net        : capitauxDeces["M. Arthur MICHAUD"]! - taxeEnfant,
            //                            tax        : taxeEnfant),
            //                Inheritance(personName : "Mme. Lou-Ann MICHAUD",
            //                            percent    : capitauxDeces["Mme. Lou-Ann MICHAUD"]! / totalTaxableInheritanceValue,
            //                            brut       : capitauxDeces["Mme. Lou-Ann MICHAUD"]!,
            //                            abatFrac   : 0.5,
            //                            net        : capitauxDeces["Mme. Lou-Ann MICHAUD"]! - taxeEnfant,
            //                            tax        : taxeEnfant)
            //            ]
            //
            //            let lifeInsSuccession = Succession(kind         : .lifeInsurance,
            //                                               yearOfDeath  : 2021,
            //                                               decedentName : decedentName,
            //                                               taxableValue : totalTaxableInheritanceValue,
            //                                               inheritances : inheritances)
            //
            //            let legalSuccession =
            //                legalSuccessionManager.legalSuccession(of      : adultDecedentName,
            //                                                       with    : patrimoine,
            //                                                       verbose : verbose)
            
            //            legalSuccession = Succession(kind         : .legal,
            //                                         yearOfDeath  : 2021,
            //                                         decedentName : decedentName,
            //                                         taxableValue : 100,
            //                                         inheritances: [conjointInheritance,
            //                                                        enfant1Inheritance,
            //                                                        enfant2Inheritance])
            //
            
            Tests.manager.computeCashAndTaxesPerPerson(legalSuccessions   : [Succession(kind: .legal,
                                                                                        yearOfDeath: 2021,
                                                                                        decedentName: decedentName,
                                                                                        taxableValue: 0.0,
                                                                                        inheritances: [])],
                                                       lifeInsSuccessions : [lifeInsSuccession],
                                                       verbose            : Tests.verbose)
            
            let theory_lifeInsSuccessionsTaxesAdults = [NamedValue(name: decedentName, value: 0.0),
                                                        NamedValue(name: spouseName, value: 0.0)]
            let theory_lifeInsSuccessionsTaxesChildren: NamedValueArray = [NamedValue(name: childrenName.first!, value: taxeEnfant),
                                                                           NamedValue(name: childrenName.last!,  value: taxeEnfant)]
            XCTAssertTrue(theory_lifeInsSuccessionsTaxesAdults.containsSameElements(as: Tests.manager.lifeInsurance.taxesAdults))
            XCTAssertTrue(theory_lifeInsSuccessionsTaxesChildren.containsSameElements(as: Tests.manager.lifeInsurance.taxesChildren))
        }
        
        func test_totalChildrenInheritanceTaxe() {
            let decedentName = "M. Lionel MICHAUD"
            let spouseName   = "Mme. Vanessa MICHAUD"
            let childrenName = ["M. Arthur MICHAUD", "Mme. Lou-Ann MICHAUD"]
            
            // créer les managers
            var lifeInsuranceSuccessionManager =
                LifeInsuranceSuccessionManager(using          : Tests.fiscalModel,
                                               familyProvider : Tests.family,
                                               atEndOf        : 2021)
            
            // calculers les succession (testées de par ailleurs)
            let lifeInsSuccession =
                lifeInsuranceSuccessionManager.succession(
                    of           : decedentName,
                    with         : Tests.patrimoin,
                    spouseName   : spouseName,
                    childrenName : Tests.family.childrenAliveName(atEndOf : 2021),
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

            let capitauxDeces = ["Mme. Vanessa MICHAUD" : theory_free_av_boul_van + theory_free_av_afel_van,
                                 "M. Arthur MICHAUD"    : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf,
                                 "Mme. Lou-Ann MICHAUD" : therory_period_tonl_enf + theory_free_av_boul_enf + theory_free_av_afel_enf]

            let taxeEnfant = (capitauxDeces["M. Arthur MICHAUD"]! - 0.5 * 152500.0) * 0.2
//

            let childrenInheritancesTaxe =
                Tests.manager.totalChildrenInheritanceTaxe(legalSuccession   : Succession(kind: .legal,
                                                                                          yearOfDeath: 2021,
                                                                                          decedentName: decedentName,
                                                                                          taxableValue: 0.0,
                                                                                          inheritances: []),
                                                           lifeInsSuccession : lifeInsSuccession,
                                                           verbose           : Tests.verbose)
            
            let theory = [childrenName.first : taxeEnfant,
                          childrenName.last  : taxeEnfant]
            
            XCTAssertEqual(theory, childrenInheritancesTaxe)
        }
        
        func test_makeSureChildrenCanPaySuccessionTaxes() {
            
        }
        
        func test_manageSuccession() {
            
        }
    }
