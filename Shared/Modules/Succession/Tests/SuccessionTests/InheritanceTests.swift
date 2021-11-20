import XCTest
@testable import Succession

final class InheritanceTests: XCTestCase {
    
    static let heritier1 = Inheritance(personName    : "Héritier 1",
                                       percentFiscal : 0.4,
                                       brutFiscal    : 40_000,
                                       abatFrac      : 0.94,
                                       netFiscal     : 35_000,
                                       tax           : 5_000,
                                       received      : 30_000,
                                       receivedNet   : 25_000,
                                       creanceRestit : 38_000)
    static let heritier2 = Inheritance(personName    : "Héritier 2",
                                       percentFiscal : 0.4,
                                       brutFiscal    : 20_000,
                                       abatFrac      : 0.92,
                                       netFiscal     : 25_000,
                                       tax           : 4_000,
                                       received      : 10_000,
                                       receivedNet   : 15_000,
                                       creanceRestit : 28_000)
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
