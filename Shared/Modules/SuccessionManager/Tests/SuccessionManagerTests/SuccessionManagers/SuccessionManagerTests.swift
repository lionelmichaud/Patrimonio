import Succession
import FamilyModel
import AssetsModel
import XCTest
    @testable import SuccessionManager

    final class SuccessionManagerTests: XCTestCase {

        static var family: Family!
        
        override class func setUp() {
            super.setUp()
//            SuccessionManagerTests.family = Family(
//                fromFile             : RealEstateAsset.defaultFileName,
//                fromBundle           : Bundle.module,
//                dateDecodingStrategy : .iso8601,
//                keyDecodingStrategy  : .useDefaultKeys)
//            
//            RealEstateAsset.setFiscalModelProvider(
//                Fiscal.Model(fromFile   : "FiscalModelConfig.json",
//                             fromBundle : Bundle.module)
//                    .initialized())
        }
        
        func test_totalChildrenInheritanceTaxe() {
            // This is an example of a functional test case.
            // Use XCTAssert and related functions to verify your tests produce the correct
            // results.
            var legalSuccession     : Succession
            var lifeInsSuccession   : Succession
            var conjointInheritance : Inheritance
            var enfant1Inheritance  : Inheritance
            var enfant2Inheritance  : Inheritance
            
            conjointInheritance = Inheritance(personName: "conjoint",
                                              percent: 0.2,
                                              brut: 50,
                                              net: 40,
                                              tax: 10)
            enfant1Inheritance = Inheritance(personName: "enfant 1",
                                              percent: 0.2,
                                              brut: 30,
                                              net: 24,
                                              tax: 6)
            enfant2Inheritance = Inheritance(personName: "enfant 2",
                                              percent: 0.2,
                                              brut: 20,
                                              net: 16,
                                              tax: 4)
            
            legalSuccession = Succession(kind: .legal,
                                         yearOfDeath: 2020,
                                         decedentName: "défunt",
                                         taxableValue: 100,
                                         inheritances: [conjointInheritance,
                                                        enfant1Inheritance,
                                                        enfant2Inheritance])
            //let childrenInheritanceTaxe = totalChildrenInheritanceTaxe(
        }
    }
