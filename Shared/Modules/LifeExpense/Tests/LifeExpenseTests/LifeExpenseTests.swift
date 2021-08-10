import XCTest
import Statistics
import SocioEconomyModel
import DateBoundary
@testable import LifeExpense

func isApproximatelyEqual(_ x: Double, _ y: Double) -> Bool {
    if x == 0 {
        return abs((x-y)) < 0.0001
    } else {
        return abs((x-y)) / x < 0.0001
    }
}

final class LifeExpenseTests: XCTestCase {
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
        var nbOfBornChildren: Int = 4
        
        func nbOfAdultAlive(atEndOf year: Int) -> Int {
            3
        }
        
        func nbOfFiscalChildren(during year: Int) -> Int {
            2
        }
    }
    static let membersCountProvider = MembersCountProvider()
    
    // MARK: Helpers
    
    override class func setUp() {
        LifeExpense.setSimulationMode(to: .deterministic)
        LifeExpense.setMembersCountProvider(membersCountProvider)
        LifeExpense.setExpensesUnderEvaluationRateProvider(underEvaluationRateProvider)
    }
    
    // MARK: Tests
    
    func test_permanent_expense() {
        let value = 10.0
        let expense =
            LifeExpenseBuilder()
            .named("dépense")
            .annotated(with: "Permanente")
            .valued(at: value)
            .permanently()
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertEqual(expense.name, "dépense")
        XCTAssertEqual(expense.note, "Permanente")
        XCTAssertEqual(expense.value, value)
        XCTAssertEqual(expense.proportional, false)
        XCTAssertEqual(expense.timeSpan, .permanent)
        XCTAssertEqual(expense.firstYear, Date.now.year)
        XCTAssertEqual(expense.lastYear, Date.now.year + 100)
        LifeExpense.setSimulationMode(to: .deterministic)
        XCTAssertEqual(expense.value(atEndOf: Date.now.year),
                       value * (1.0 + LifeExpenseTests
                                    .underEvaluationRateProvider
                                    .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        )
        
        LifeExpense.setSimulationMode(to: .random)
        XCTAssertEqual(expense.value(atEndOf: Date.now.year),
                       value * (1.0 + LifeExpenseTests
                                    .underEvaluationRateProvider
                                    .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        )
        
        print(String(describing: expense))
    }
    
    func test_exceptional_expense() {
        let value = 10.0
        let year  = 2022
        let expense =
            LifeExpenseBuilder()
            .named("dépense2")
            .annotated(with: "Exceptionnelle")
            .valued(at: value)
            .exceptionnaly(inYear: year)
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertEqual(expense.name, "dépense2")
        XCTAssertEqual(expense.note, "Exceptionnelle")
        XCTAssertEqual(expense.value, value)
        XCTAssertEqual(expense.proportional, false)
        XCTAssertEqual(expense.timeSpan, .exceptional(inYear: year))
        XCTAssertEqual(expense.firstYear, year)
        XCTAssertEqual(expense.lastYear, year)
        LifeExpense.setSimulationMode(to: .deterministic)
        XCTAssertEqual(expense.value(atEndOf: year),
                       value * (1.0 + LifeExpenseTests
                                    .underEvaluationRateProvider
                                    .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        )
        XCTAssertEqual(expense.value(atEndOf: year - 1), 0.0)
        XCTAssertEqual(expense.value(atEndOf: year + 1), 0.0)
        LifeExpense.setSimulationMode(to: .random)
        XCTAssertEqual(expense.value(atEndOf: year),
                       value * (1.0 + LifeExpenseTests
                                    .underEvaluationRateProvider
                                    .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        )
        
        print(String(describing: expense))
    }
    
    func test_starting_expense() {
        let value = 10.0
        let year  = 2022
        let startYear = DateBoundaryBuilder()
            .fixedYear(year)
            .build()
        let expense =
            LifeExpenseBuilder()
            .named("dépense3")
            .annotated(with: "Débutant...")
            .valued(at: value)
            .starting(from: startYear)
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertEqual(expense.name, "dépense3")
        XCTAssertEqual(expense.note, "Débutant...")
        XCTAssertEqual(expense.value, value)
        XCTAssertEqual(expense.proportional, false)
        XCTAssertEqual(expense.timeSpan, .starting(from: startYear))
        XCTAssertEqual(expense.firstYear, year)
        XCTAssertEqual(expense.lastYear, Date.now.year + 100)
        LifeExpense.setSimulationMode(to: .deterministic)
        let deterministicValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year - 1), 0.0)
        XCTAssertEqual(expense.value(atEndOf: year + 1), deterministicValue)
        
        LifeExpense.setSimulationMode(to: .random)
        let randomValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year), randomValue)
        
        print(String(describing: expense))
    }
    
    func test_ending_expense() {
        let value = 10.0
        let year  = 2028
        let endYear = DateBoundaryBuilder()
            .fixedYear(year)
            .build()
        let expense =
            LifeExpenseBuilder()
            .named("dépense4")
            .annotated(with: "Se terminant")
            .valued(at: value)
            .ending(to: endYear)
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertEqual(expense.name, "dépense4")
        XCTAssertEqual(expense.note, "Se terminant")
        XCTAssertEqual(expense.value, value)
        XCTAssertEqual(expense.proportional, false)
        XCTAssertEqual(expense.timeSpan, .ending(to: endYear))
        XCTAssertEqual(expense.firstYear, Date.now.year)
        XCTAssertEqual(expense.lastYear, year-1)
        LifeExpense.setSimulationMode(to: .deterministic)
        let deterministicValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: Date.now.year), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year - 1), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year), 0.0) // la dernière année est exclue
        
        LifeExpense.setSimulationMode(to: .random)
        let randomValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year - 1), randomValue)
        
        print(String(describing: expense))
    }
    
    func test_spanning_expense() {
        let value = 10.0
        let year  = 2028
        let startYear = DateBoundaryBuilder()
            .fixedYear(year)
            .build()
        let endYear = DateBoundaryBuilder()
            .fixedYear(year+10)
            .build()
        let expense =
            LifeExpenseBuilder()
            .named("dépense5")
            .annotated(with: "De...à...")
            .valued(at: value)
            .spanning(from: startYear, to: endYear)
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertEqual(expense.name, "dépense5")
        XCTAssertEqual(expense.note, "De...à...")
        XCTAssertEqual(expense.value, value)
        XCTAssertEqual(expense.proportional, false)
        XCTAssertEqual(expense.timeSpan, .spanning(from: startYear, to: endYear))
        XCTAssertEqual(expense.firstYear, year)
        XCTAssertEqual(expense.lastYear, year + 10 - 1) // la dernière année est exclue
        LifeExpense.setSimulationMode(to: .deterministic)
        let deterministicValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year - 1), 0.0)
        XCTAssertEqual(expense.value(atEndOf: year), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year + 10 - 1), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year + 10), 0.0) // la dernière année est exclue
        
        LifeExpense.setSimulationMode(to: .random)
        let randomValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year), randomValue)
        XCTAssertEqual(expense.value(atEndOf: year + 10 - 1), randomValue)
        
        print(String(describing: expense))
    }
    
    func test_periodically_expense() {
        let value  = 10.0
        let year   = 2028
        let period = 5
        let startYear = DateBoundaryBuilder()
            .fixedYear(year)
            .build()
        let endYear = DateBoundaryBuilder()
            .fixedYear(year+11)
            .build()
        let expense =
            LifeExpenseBuilder()
            .named("dépense5")
            .annotated(with: "Périodique")
            .valued(at: value)
            .periodically(from: startYear, to: endYear, withPeriod: period)
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertEqual(expense.name, "dépense5")
        XCTAssertEqual(expense.note, "Périodique")
        XCTAssertEqual(expense.value, value)
        XCTAssertEqual(expense.proportional, false)
        XCTAssertEqual(expense.timeSpan, .periodic(from: startYear, period: period, to: endYear))
        XCTAssertEqual(expense.firstYear, year)
        XCTAssertEqual(expense.lastYear, year + 10) // la dernière année est exclue
        LifeExpense.setSimulationMode(to: .deterministic)
        let deterministicValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year - 1), 0.0)
        XCTAssertEqual(expense.value(atEndOf: year), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year + 5), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year + 10), deterministicValue)
        XCTAssertEqual(expense.value(atEndOf: year + 11), 0.0) // la dernière année est exclue
        
        LifeExpense.setSimulationMode(to: .random)
        let randomValue =
            value * (1.0 + LifeExpenseTests
                        .underEvaluationRateProvider
                        .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: year + 5), randomValue)
        XCTAssertEqual(expense.value(atEndOf: year + 10), randomValue)
        
        print(String(describing: expense))
    }
    
    func test_proportional_expense() {
        let value = 10.0
        let expense =
            LifeExpenseBuilder()
            .named("dépense")
            .annotated(with: "Proportionnelle")
            .valued(at: value)
            .permanently()
            .isProportionalToFamilyMembersCount(true)
            .build()
        XCTAssertEqual(expense.proportional, true)
        LifeExpense.setSimulationMode(to: .deterministic)
        let deterministicValue =
            (3 + 2) * value * (1.0 + LifeExpenseTests
                                .underEvaluationRateProvider
                                .expensesUnderEvaluationRate(withMode: .deterministic) / 100.0)
        XCTAssertEqual(expense.value(atEndOf: Date.now.year), deterministicValue)
        
        LifeExpense.setSimulationMode(to: .random)
        let randomValue =
            (3 + 2) * value * (1.0 + LifeExpenseTests
                                .underEvaluationRateProvider
                                .expensesUnderEvaluationRate(withMode: .random) / 100.0)
        XCTAssertTrue(isApproximatelyEqual(expense.value(atEndOf: Date.now.year), randomValue))
        
        print(String(describing: expense))
    }
    
    func test_compare() {
        let value = 10.0
        let expense =
            LifeExpenseBuilder()
            .named("dépense 1")
            .annotated(with: "Permanente")
            .valued(at: value)
            .permanently()
            .isProportionalToFamilyMembersCount(false)
            .build()
        let expense2 =
            LifeExpenseBuilder()
            .named("dépense 2")
            .annotated(with: "Permanente")
            .valued(at: value)
            .permanently()
            .isProportionalToFamilyMembersCount(false)
            .build()
        XCTAssertTrue(expense < expense2)
    }
    
}
