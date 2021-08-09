//
//  Expense.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Persistable
import Statistics
import SocioEconomyModel
import NamedValue
import DateBoundary

// MARK: - Tableau de Dépenses

struct LifeExpenseArray: NameableValuableArrayP {

    private enum CodingKeys: String, CodingKey {
        case items
    }

    // MARK: - Properties
    
    var items         = [LifeExpense]()
    var persistenceSM = PersistenceStateMachine(initialState : .created)

    // MARK: - Initializers: voir NameableValuableArray
}

extension LifeExpenseArray: CustomStringConvertible {
    var description: String {
        var desc = ""
        items.sorted().forEach { expense in
            desc += "\(String(describing: expense).withPrefixedSplittedLines("  "))\n"
        }
        return desc
    }
}

// MARK: - Dépense de la famille

struct LifeExpense: Identifiable, Codable, Hashable, NameableValuableP {
    
    // MARK: - Static properties
    
    static let prototype = LifeExpense(name     : "",
                                       note     : "",
                                       timeSpan : .permanent,
                                       value    : 0.0)
    private static var simulationMode : SimulationModeEnum = .deterministic
    // dependencies
    private static var membersCountProvider : MembersCountProviderP!
    private static var expensesUnderEvaluationRateProvider : ExpensesUnderEvaluationRateProviderP!

    // MARK: - Static Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        LifeExpense.simulationMode = simulationMode
    }

    static func setMembersCountProvider(_ membersCountProvider: MembersCountProviderP) {
        LifeExpense.membersCountProvider = membersCountProvider
    }
    
    static func setExpensesUnderEvaluationRateProvider(_ expensesUnderEvaluationRateProvider: ExpensesUnderEvaluationRateProviderP) {
        LifeExpense.expensesUnderEvaluationRateProvider = expensesUnderEvaluationRateProvider
    }
    
   /// Calcule le facteur aléatoire de correction à appliquer
    /// - Note: valeur > 1.0
    static var correctionFactor: Double {
        1.0 + LifeExpense.expensesUnderEvaluationRateProvider.expensesUnderEvaluationRate(withMode: simulationMode) / 100.0
    }
    
    // MARK: - Properties
    
    var id           = UUID()
    var name         : String = ""
    var note         : String
    var value        : Double = 0.0
    var proportional : Bool   = false
    var timeSpan     : TimeSpan
    
    // MARK: - Computed properties
    
    var firstYear: Int? { // computed
        timeSpan.firstYear
    }
    
    var lastYear: Int? { // computed
        timeSpan.lastYear
    }
    
    // MARK: - Initializers
    
    init(name         : String,
         note         : String,
         timeSpan     : TimeSpan,
         proportional : Bool = false,
         value        : Double) {
        self.name         = name
        self.value        = value
        self.note         = note
        self.proportional = proportional
        self.timeSpan     = timeSpan
    }
    
    // MARK: - Methods
    
    func value(atEndOf year: Int) -> Double {
        if timeSpan.contains(year) {
            if proportional {
                if let membersCountProvider = LifeExpense.membersCountProvider {
                    let nbMembers = membersCountProvider.nbOfAdultAlive(atEndOf: year) +
                        membersCountProvider.nbOfFiscalChildren(during: year)
                    return value * LifeExpense.correctionFactor * nbMembers.double()
                } else {
                    return 0
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
    static func < (lhs: LifeExpense, rhs: LifeExpense) -> Bool { (lhs.name < rhs.name) }
}

extension LifeExpense: CustomStringConvertible {
    var description: String {
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
