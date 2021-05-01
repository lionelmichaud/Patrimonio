//
//  DemembrementModelTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 14/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import FiscalModel

class DemembrementModelTests: XCTestCase {
    
    static var demembrement: DemembrementModel!
    
    // MARK: Helpers
    
//    override func setUp() {
//        super.setUp()
//
//
////        let model = DemembrementModel.Model(for: DemembrementModelTests.self,
////                                            from                 : nil,
////                                            dateDecodingStrategy : .iso8601,
////                                            keyDecodingStrategy  : .useDefaultKeys)
////        DemembrementModelTests.demembrement = DemembrementModel(model: model)
//    }
//
    // MARK: Tests
    func test_load() {
        let model = DemembrementModel.Model(for: DemembrementModelTests.self,
                                            from                 : nil,
                                            dateDecodingStrategy : .iso8601,
                                            keyDecodingStrategy  : .useDefaultKeys)
        DemembrementModelTests.demembrement = DemembrementModel(model: model)

        let url = Bundle.module.url(forResource: DemembrementModel.Model.defaultFileName, withExtension: nil)
        print(url)
        guard let data = try? Data(contentsOf: url!) else {
            fatalError("Failed to load file '\(DemembrementModel.Model.defaultFileName)' from bundle.")
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys
        let failureString = "Failed to decode object of type '\(String(describing: DemembrementModel.Model.self))' from file '\(DemembrementModel.Model.defaultFileName)' "
        do {
            let model = try decoder.decode(DemembrementModel.Model.self, from: data)
            DemembrementModelTests.demembrement = DemembrementModel(model: model)
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("\(failureString)from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("\(failureString)from bundle due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("\(failureString)from bundle due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("\(failureString)from bundle because it appears to be invalid JSON \n \(context.codingPath) \n \(context.debugDescription)")
        } catch {
            fatalError("\(failureString)from bundle: \(error.localizedDescription)")
        }

    }
    func test_demembrement_outOfBound() {
        XCTAssertThrowsError(try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: -1)) { error in
            XCTAssertEqual(error as! DemembrementModel.ModelError, DemembrementModel.ModelError.outOfBounds)
        }
    }
    
    func test_demembrement() throws {
        var demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 20)
        XCTAssertEqual(90.0, demembrement.usufructValue)
        XCTAssertEqual(10.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 30)
        XCTAssertEqual(80.0, demembrement.usufructValue)
        XCTAssertEqual(20.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 50)
        XCTAssertEqual(60.0, demembrement.usufructValue)
        XCTAssertEqual(40.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 60)
        XCTAssertEqual(50.0, demembrement.usufructValue)
        XCTAssertEqual(50.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 80)
        XCTAssertEqual(30.0, demembrement.usufructValue)
        XCTAssertEqual(70.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 90)
        XCTAssertEqual(20.0, demembrement.usufructValue)
        XCTAssertEqual(80.0, demembrement.bareValue)

        demembrement = try DemembrementModelTests.demembrement.demembrement(of: 100.0, usufructuaryAge: 100)
        XCTAssertEqual(10.0, demembrement.usufructValue)
        XCTAssertEqual(90.0, demembrement.bareValue)
    }
}
