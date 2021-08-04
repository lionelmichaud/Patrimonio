import XCTest
@testable import Succession

final class InheritanceTests: XCTestCase {
    
    static let heritier1 = Inheritance(personName: "Héritier 1", percent: 0.4, brut: 40_000, net: 35_000, tax: 5_000)
    static let heritier2 = Inheritance(personName: "Héritier 2", percent: 0.6, brut: 60_000, net: 50_000, tax: 10_000)
    static var array     = [Inheritance]()
    static var succession : Succession!
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        InheritanceTests.array = [heritier1, heritier2]
    }
    
    // MARK: Tests
    
    func test_description() {
        print("Test de Inheritance.description")
        
        let str: String =
            String(describing: InheritanceTests.heritier1)
        print(str)
    }
}
