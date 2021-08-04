import XCTest
@testable import Succession

final class SuccessionTests: XCTestCase {
    static let héritage1 = Inheritance(personName: "Héritier 1", percent: 0.4, brut: 40_000, net: 35_000, tax: 5_000)
    static let héritage2 = Inheritance(personName: "Héritier 2", percent: 0.6, brut: 60_000, net: 50_000, tax: 10_000)
    static let héritage3 = Inheritance(personName: "Héritier 1", percent: 0.5, brut: 50_000, net: 40_000, tax: 10_000)
    static let héritage4 = Inheritance(personName: "Héritier 2", percent: 0.5, brut: 50_000, net: 40_000, tax: 10_000)
    static var succession1 : Succession!
    static var succession2 : Succession!
    static var successions : [Succession]!

    // MARK: - Helpers
    
    override class func setUp() {
        super.setUp()
        SuccessionTests.succession1 = Succession(kind: .legal,
                                                 yearOfDeath: 2048,
                                                 decedentName: "Défunt",
                                                 taxableValue: 100,
                                                 inheritances: [SuccessionTests.héritage1,
                                                                SuccessionTests.héritage2])
        SuccessionTests.succession2 = Succession(kind: .legal,
                                                 yearOfDeath: 2048,
                                                 decedentName: "Défunt",
                                                 taxableValue: 100,
                                                 inheritances: [SuccessionTests.héritage3,
                                                                SuccessionTests.héritage4])
        SuccessionTests.successions = [SuccessionTests.succession1,
                                       SuccessionTests.succession2]
    }
    
    // MARK: Tests
    
    func test_description() {
        print("Test de Succession.description")
        
        let str: String =
            String(describing: SuccessionTests.succession1!)
        print(str)
    }
    
    func test_successorsInheritedNetValue() {
        // dictionnaire des héritages net reçu par chaque héritier sur un ensemble de successions
        var successorsInheritedNetValue: [String: Double] =
            SuccessionTests.successions.successorsInheritedNetValue
        XCTAssertTrue(successorsInheritedNetValue.count > 0)
        XCTAssertEqual(successorsInheritedNetValue["Héritier 1"], 75_000)
        XCTAssertEqual(successorsInheritedNetValue["Héritier 2"], 90_000)
        
        // dictionnaire des héritages net reçu par chaque héritier dans une succession
        successorsInheritedNetValue = SuccessionTests.succession1.successorsInheritedNetValue
        XCTAssertTrue(successorsInheritedNetValue.count > 0)
        XCTAssertEqual(successorsInheritedNetValue["Héritier 1"], 35_000)
        XCTAssertEqual(successorsInheritedNetValue["Héritier 2"], 50_000)
    }
    
    func test_somme_des_héritages_reçus_par_les_héritiers_dans_une_succession() {
        let somme = SuccessionTests.succession1.net
        XCTAssertEqual(somme, 85_000)
    }
    
    func test_somme_des_taxes_payées_par_les_héritiers_dans_une_succession() {
        let somme = SuccessionTests.succession1.tax
        XCTAssertEqual(somme, 15_000)
    }

}
