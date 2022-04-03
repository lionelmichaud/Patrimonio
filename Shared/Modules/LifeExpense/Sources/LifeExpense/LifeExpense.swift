//
//  Expense.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import Persistable
import Statistics
import SocioEconomyModel
import NamedValue
import DateBoundary

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "Model.LifeExpense")

// MARK: - Tableau de Dépenses

public struct LifeExpenseArray: NameableValuableArrayP {

    public static var empty = LifeExpenseArray(items: [], persistenceSM: PersistenceStateMachine(initialState : .created))
    
    private enum CodingKeys: String, CodingKey {
        case items
    }
    
    // MARK: - Properties
    
    public var items         = [LifeExpense]()
    public var persistenceSM = PersistenceStateMachine(initialState : .created)
    
    // MARK: - Initializers: voir NameableValuableArray
}

extension LifeExpenseArray: CustomStringConvertible {
    public var description: String {
        var desc = ""
        items.sorted().forEach { expense in
            desc += "\(String(describing: expense).withPrefixedSplittedLines("  "))\n"
        }
        return desc
    }
}

// MARK: - Dépense de la famille

public struct LifeExpense: Identifiable, Codable, Hashable, NameableValuableP {
    
    // MARK: - Type properties
    
    public static let prototype = LifeExpense(name     : "",
                                              note     : "",
                                              timeSpan : .permanent,
                                              value    : 0.0)
    private static var simulationMode : SimulationModeEnum = .deterministic
    // dependencies
    private static var membersCountProvider : MembersCountProviderP!
    private static var expensesUnderEvaluationRateProvider : ExpensesUnderEvaluationRateProviderP!
    
    // MARK: - Type Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    public static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        LifeExpense.simulationMode = simulationMode
    }
    
    public static func setMembersCountProvider(_ membersCountProvider: MembersCountProviderP) {
        LifeExpense.membersCountProvider = membersCountProvider
    }
    
    public static func setExpensesUnderEvaluationRateProvider(_ expensesUnderEvaluationRateProvider: ExpensesUnderEvaluationRateProviderP) {
        LifeExpense.expensesUnderEvaluationRateProvider = expensesUnderEvaluationRateProvider
    }
    
    /// Calcule le facteur aléatoire de correction à appliquer
    /// - Note: valeur > 1.0
    static var correctionFactor: Double {
        1.0 + LifeExpense
            .expensesUnderEvaluationRateProvider
            .expensesUnderEvaluationRate(withMode: simulationMode) / 100.0
    }
    
    // MARK: - Properties
    
    public var id           = UUID()
    public var name         : String   = ""
    public var note         : String   = ""
    public var value        : Double   = 0.0
    public var proportional : Bool     = false
    public var timeSpan     : TimeSpan = .permanent
    
    // MARK: - Computed properties
    
    var firstYear: Int? { // computed
        timeSpan.firstYear
    }
    
    var lastYear: Int? { // computed
        timeSpan.lastYear
    }
    
    // MARK: - Initializers
    
    public init(name         : String   = "",
                note         : String   = "",
                timeSpan     : TimeSpan = .permanent,
                proportional : Bool     = false,
                value        : Double   = 0.0) {
        self.name         = name
        self.value        = value
        self.note         = note
        self.proportional = proportional
        self.timeSpan     = timeSpan
    }
    
    // MARK: - Methods
    
    public func value(atEndOf year: Int) -> Double {
        if timeSpan.contains(year) {
            if proportional {
                if let membersCountProvider = LifeExpense.membersCountProvider {
                    let nbMembers = membersCountProvider.nbOfAdultAlive(atEndOf: year) +
                        membersCountProvider.nbOfFiscalChildren(during: year)
                    return value * LifeExpense.correctionFactor * nbMembers.double()
                } else {
                    customLog.log(level: .fault, "LifeExpense.membersCountProvider is not set (nil). Dependency issue.")
                    fatalError("LifeExpense.membersCountProvider is not set (nil). Dependency issue.")
                }
            } else {
                return value * LifeExpense.correctionFactor
            }
        } else {
            return 0.0
        }
    }
}

extension LifeExpense: Comparable {
    public static func < (lhs: LifeExpense, rhs: LifeExpense) -> Bool { (lhs.name < rhs.name) }
}

extension LifeExpense: CustomStringConvertible {
    public var description: String {
        """

        DEPENSE: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Montant: \(value.€String)
        - Proportionnel au nombre de membres de la famille: \(proportional.frenchString)
        - Période: \(timeSpan.description.withPrefixedSplittedLines("  "))
        """
    }
}
