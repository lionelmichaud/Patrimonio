//
//  Loan.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import NamedValue
import Ownership

public typealias LoanArray = ArrayOfNameableValuable<Loan>

// MARK: - Emprunt à remboursement constant, périodique, annuel et à taux fixe

/// Emprunt à remboursement constant, périodique, annuel et à taux fixe
public struct Loan: Codable, Identifiable, NameableValuableP, OwnableP {
    
    // MARK: - Type Properties

    public static let prototype = Loan()

    // MARK: - Properties
    
    public var id                = UUID()
    public var name              : String = ""
    public var note              : String = ""
    // propriétaires
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    public var ownership         : Ownership = Ownership()
    
    public var firstYear         : Int // au 31 décembre
    public var lastYear          : Int // au 31 décembre
    public var loanedValue       : Double = 0 // negative number
    public var interestRate      : Double = 0// %
    public var monthlyInsurance  : Double = 0 // cout mensuel
    private var nbPeriod  : Int {
        (lastYear - firstYear + 1)
    }
    private var yearlyPayement: Double {
        loanPayement(loanedValue  : loanedValue,
                       interestRate : interestRate/100.0,
                     nbPeriod     : nbPeriod) +
            12 * monthlyInsurance
    }
    public var totalPayement     : Double {
        yearlyPayement * nbPeriod.double()
    }
    public var costOfCredit      : Double {
        totalPayement + loanedValue
    }
    
    // MARK: - Initializers
    
    public init(name             : String  = "",
                note             : String  = "",
                value            : Double  = 0,
                interestRate     : Double  = 1,
                delegateForAgeOf : ((_ name : String, _ year : Int) -> Int)?  = nil,
                firstYear        : Int = CalendarCst.thisYear,
                lastYear         : Int = CalendarCst.thisYear) {
        self.name         = name
        self.note         = note
        self.ownership.setDelegateForAgeOf(delegate : delegateForAgeOf)
        self.firstYear    = firstYear
        self.lastYear     = lastYear
        self.interestRate = interestRate
    }
    
    // MARK: - Methods
    
    /// Montant du remboursement périodique (capital + intérêts)
    /// - Parameter year: année courante
    public func yearlyPayement(_ year: Int) -> Double {
        ((firstYear...lastYear).contains(year) ? yearlyPayement : 0.0)
    }
    /// Montant des remboursements restants dûs
    /// - Parameter year: année courante
    /// - Returns: valeur négative
    public func value(atEndOf year: Int) -> Double {
        ((firstYear...lastYear).contains(year) ?
            yearlyPayement * (lastYear - year).double() :
            0.0)
    }
}

// MARK: Extensions
extension Loan: Comparable {
    public static func < (lhs: Loan, rhs: Loan) -> Bool {
        (lhs.name < rhs.name)
    }
}

extension Loan: CustomStringConvertible {
    public var description: String {
        """
        EMPRUNT: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - valeur(\(CalendarCst.thisYear): \(value(atEndOf: CalendarCst.thisYear).€String)
        - first year:       \(firstYear) last year: \(lastYear)
        - loaned Value:     \(loanedValue) final Value: \(value(atEndOf: lastYear).€String)
        - yearly Payement:  \(yearlyPayement.€String)
        - interest Rate:    \(interestRate) %
        - monthly Insurance:\(monthlyInsurance) %
        """
    }
}
