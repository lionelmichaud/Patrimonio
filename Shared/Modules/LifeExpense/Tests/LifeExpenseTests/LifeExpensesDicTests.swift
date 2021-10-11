//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 10/08/2021.
//

import XCTest
import Statistics
import SocioEconomyModel
import DateBoundary
@testable import LifeExpense

final class LifeExpenseDicTests: XCTestCase {
    
    struct ExpensesUnderEvaluationRateProvider: ExpensesUnderEvaluationRateProviderP {
        func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            switch simulationMode {
                case .deterministic:
                    return 5.0
                case .random:
                    return 10.0
            }
        }
    }
    static let underEvaluationRateProvider = ExpensesUnderEvaluationRateProvider()
    
    struct MembersCountProvider : MembersCountProviderP {
        var nbOfAdults: Int = 2
        
        var nbOfBornChildren: Int = 4
        
        func nbOfAdultAlive(atEndOf year: Int) -> Int {
            3
        }
        
        func nbOfChildrenAlive(atEndOf year: Int) -> Int {
            2
        }

        func nbOfFiscalChildren(during year: Int) -> Int {
            2
        }
    }
    static let membersCountProvider = MembersCountProvider()
    static var expenseDico          = LifeExpensesDic()
    
    // MARK: Helpers
    
    override class func setUp() {
        LifeExpense.setSimulationMode(to: .deterministic)
        LifeExpense.setMembersCountProvider(membersCountProvider)
        LifeExpense.setExpensesUnderEvaluationRateProvider(underEvaluationRateProvider)
        
        let value = 10.0
        var expense =
            LifeExpenseBuilder()
            .named("abonnements")
            .annotated(with: "Permanente")
            .valued(at: value)
            .permanently()
            .isProportionalToFamilyMembersCount(false)
            .build()
        var array = LifeExpenseArray()
        array.items.append(expense)
        expenseDico[.abonnements] = array
        
        let year  = 2022
        expense =
            LifeExpenseBuilder()
            .named("cadeaux")
            .annotated(with: "Exceptionnelle")
            .valued(at: 20.0)
            .exceptionnaly(inYear: year)
            .isProportionalToFamilyMembersCount(true)
            .build()
        array = LifeExpenseArray()
        array.items.append(expense)
        expenseDico[.cadeaux] = array
    }
    
    // MARK: Tests
    
    func test_description() {
        print(String(describing: LifeExpenseDicTests.expenseDico))
    }
    
    func test_expensesNameArray() {
        var expensesNameArray = LifeExpenseDicTests.expenseDico
            .expensesNameArray(of: .cadeaux)
        XCTAssertEqual(["cadeaux"], expensesNameArray)
        expensesNameArray = LifeExpenseDicTests.expenseDico
            .expensesNameArray(of: .abonnements)
        XCTAssertEqual(["abonnements"], expensesNameArray)
    }
    
    func test_namedValuedTimeFrameTable() {
        var namedValuedTimeFrameTable = LifeExpenseDicTests.expenseDico
            .namedValuedTimeFrameTable(category: .cadeaux)
        XCTAssertEqual(namedValuedTimeFrameTable.count, 1)
        XCTAssertEqual(namedValuedTimeFrameTable[0].name, "cadeaux")
        XCTAssertEqual(namedValuedTimeFrameTable[0].value, 20.0)
        XCTAssertEqual(namedValuedTimeFrameTable[0].prop, true)
        XCTAssertEqual(namedValuedTimeFrameTable[0].idx, 0)
        XCTAssertEqual(namedValuedTimeFrameTable[0].firstYearDuration, [2022, 1])

        namedValuedTimeFrameTable = LifeExpenseDicTests.expenseDico
            .namedValuedTimeFrameTable(category: .abonnements)
        XCTAssertEqual(namedValuedTimeFrameTable.count, 1)
        XCTAssertEqual(namedValuedTimeFrameTable[0].name, "abonnements")
        XCTAssertEqual(namedValuedTimeFrameTable[0].value, 10.0)
        XCTAssertEqual(namedValuedTimeFrameTable[0].prop, false)
        XCTAssertEqual(namedValuedTimeFrameTable[0].idx, 0)
        XCTAssertEqual(namedValuedTimeFrameTable[0].firstYearDuration, [Date.now.year, 101])

        namedValuedTimeFrameTable = LifeExpenseDicTests.expenseDico
            .namedValuedTimeFrameTable(category: nil)
        XCTAssertEqual(namedValuedTimeFrameTable.count, 2)
        XCTAssertTrue(namedValuedTimeFrameTable.contains(where: { $0.name == "cadeaux" }))
        XCTAssertTrue(namedValuedTimeFrameTable.contains(where: { $0.name == "abonnements" }))
        XCTAssertEqual(namedValuedTimeFrameTable[0].value, 20.0)
        XCTAssertEqual(namedValuedTimeFrameTable[0].prop, true)
        XCTAssertEqual(namedValuedTimeFrameTable[0].idx, 0)
        XCTAssertEqual(namedValuedTimeFrameTable[1].value, 10.0)
        XCTAssertEqual(namedValuedTimeFrameTable[1].prop, false)
        XCTAssertEqual(namedValuedTimeFrameTable[1].idx, 1)
    }
}
