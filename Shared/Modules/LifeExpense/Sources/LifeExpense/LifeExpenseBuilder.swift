//
//  LifeExpenseBuilder.swift
//  
//
//  Created by Lionel MICHAUD on 09/08/2021.
//

import Foundation
import DateBoundary

public class LifeExpenseBuilder {
    private var lifeExpense: LifeExpense = LifeExpense()
    
    public func named(_ name: String) -> LifeExpenseBuilder {
        lifeExpense.name = name
        return self
    }
    
    public func annotated(with note: String) -> LifeExpenseBuilder {
        lifeExpense.note = note
        return self
    }
    
    public func valued(at value: Double) -> LifeExpenseBuilder {
        lifeExpense.value = value
        return self
    }
    
    public func isProportionalToFamilyMembersCount(_ isProportional: Bool) -> LifeExpenseBuilder {
        lifeExpense.proportional = isProportional
        return self
    }
    
    public func starting(from: DateBoundary) -> LifeExpenseBuilder {
        lifeExpense.timeSpan = .starting(from: from)
        return self
    }
    
    public func ending(to: DateBoundary) -> LifeExpenseBuilder {
        lifeExpense.timeSpan = .ending(to: to)
        return self
    }
    
    public func spanning(from: DateBoundary, to: DateBoundary) -> LifeExpenseBuilder {
        lifeExpense.timeSpan = .spanning(from: from, to: to)
        return self
    }
    
    public func periodically(from: DateBoundary, to: DateBoundary, withPeriod: Int) -> LifeExpenseBuilder {
        lifeExpense.timeSpan = .periodic(from: from, period: withPeriod, to: to)
        return self
    }
    
    public func permanently() -> LifeExpenseBuilder {
        lifeExpense.timeSpan = .permanent
        return self
    }
    
    public func exceptionnaly(inYear: Int) -> LifeExpenseBuilder {
        lifeExpense.timeSpan = .exceptional(inYear: inYear)
        return self
    }
    
    func build() -> LifeExpense {
        lifeExpense
    }
}
