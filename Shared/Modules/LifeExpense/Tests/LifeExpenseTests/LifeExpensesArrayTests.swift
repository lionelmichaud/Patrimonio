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

final class LifeExpenseArrayTests: XCTestCase {
    
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
    static var expenseArray         = LifeExpenseArray()
    
    // MARK: Helpers
    
    override class func setUp() {
        LifeExpense.setSimulationMode(to: .deterministic)
        LifeExpense.setMembersCountProvider(membersCountProvider)
        LifeExpense.setExpensesUnderEvaluationRateProvider(underEvaluationRateProvider)
        
        let value = 10.0
        var expense =
            LifeExpenseBuilder()
            .named("dépense")
            .annotated(with: "Permanente")
            .valued(at: value)
            .permanently()
            .isProportionalToFamilyMembersCount(false)
            .build()
        expenseArray.items.append(expense)
        
        let year  = 2022
        expense =
            LifeExpenseBuilder()
            .named("dépense2")
            .annotated(with: "Exceptionnelle")
            .valued(at: value)
            .exceptionnaly(inYear: year)
            .isProportionalToFamilyMembersCount(false)
            .build()
        expenseArray.items.append(expense)
    }
    
    // MARK: Tests
    
    func test_description() {
        print(String(describing: LifeExpenseArrayTests.expenseArray))
    }

    func test_state() {
        XCTAssertEqual(.created, LifeExpenseArrayTests.expenseArray.persistenceState)
    }
}
