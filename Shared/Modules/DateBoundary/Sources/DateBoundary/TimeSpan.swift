//
//  LifeExpenseTimeSpan.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import AppFoundation

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.TimeSpan")

// MARK: - Elongation temporelle du poste de dépense
 
public enum TimeSpan: Hashable, Codable {
    case permanent
    // l'année de début est inclue mais la date de fin n'est pas inclue
    case periodic (from: DateBoundary, period: Int, to: DateBoundary)
    // l'année de début est inclue
    case starting (from: DateBoundary)
    // l'année de fin n'est pas inclue
    case ending   (to:   DateBoundary)
    // l'année de début est inclue mais la date de fin n'est pas inclue
    case spanning (from: DateBoundary, to: DateBoundary)
    case exceptional (inYear: Int)
    
    // MARK: - Static properties

    public static var allCases: [TimeSpan] {
        return [.permanent,
                .periodic (from: DateBoundary.empty, period: 1, to: DateBoundary.empty),
                .starting (from: DateBoundary.empty),
                .ending   (to:   DateBoundary.empty),
                .spanning (from: DateBoundary.empty, to: DateBoundary.empty),
                .exceptional (inYear: 0)]
    }
    
    // MARK: - Computed properties

    public var rawValue: Int {
        switch self {
            case .permanent:
                return 1
            case .periodic:
                return 2
            case .starting:
                return 3
            case .ending:
                return 4
            case .spanning:
                return 5
            case .exceptional:
                return 6
        }
    }
    
    // MARK: - Methods
    
    /// True si l'année demandée est inclue dans la plage de validité
    public func contains (_ year: Int) -> Bool { // swiftlint:disable:this cyclomatic_complexity
        // la dernière année est exclue
        switch self {
            case .permanent:
                return true
            
            case .periodic (let from, let period, let to):
                guard let toYear = to.year, let fromYear = from.year else {
                    customLog.log(level: .info, "contains: to.year = nil or from.year = nil")
                    return false
                }
                guard fromYear < toYear else {
//                    customLog.log(level: .info, "contains: from.year \(from.year!) > to.year \(to.year!)")
                    return false
                }
                return (fromYear ..< toYear).contains {
                    let includesYear = $0 == year
                    return includesYear && (($0 - fromYear) % period == 0)
            }
            
            case .starting (let from):
                guard let fromYear = from.year else {
                    customLog.log(level: .info, "contains: from.year = nil")
                    return false
                }
                return fromYear <= year
            
            case .ending (let to):
                guard let toYear = to.year else {
                    customLog.log(level: .info, "contains: to.year = nil")
                    return false
                }
                return year < toYear
            
            case .spanning (let from, let to):
                guard let toYear = to.year, let fromYear = from.year else {
                    customLog.log(level: .info, "contains: to.year = nil or from.year = nil")
                    return false
                }
                if fromYear > toYear { return false }
                return (fromYear ..< toYear).contains(year)
            
            case .exceptional(let inYear):
                return year == inYear
        }
    }
    
    public var firstYear: Int? { // computed
        guard isValid else {
            return nil
        }
        switch self {
            case .permanent:
                return CalendarCst.thisYear
                
            case .ending(let to):
                guard to.year != nil else {
                    customLog.log(level: .info, "firstYear: to.year = nil")
                    return nil
                }
                return min(CalendarCst.thisYear, to.year! - 1)
                
            case .periodic(let from, period: _, to: _),
                 .starting(let from),
                 .spanning(let from, to: _):
                return from.year
                
            case .exceptional(let inYear):
                return inYear
        }
    }
    
    public var lastYear: Int? { // computed
        guard isValid else {
            return nil
        }
        switch self {
            case .permanent:
                return CalendarCst.thisYear + 100
                
            case .periodic(from: _, period: _, to: let to),
                 .spanning(from: _,            to: let to),
                 .ending(let to):
                return to.year - 1
                
            case .starting(let from):
                guard from.year != nil else {
                    customLog.log(level: .info, "lastYear: from.year = nil")
                    return nil
                }
                return CalendarCst.thisYear + 100
                
            case .exceptional(inYear: let inYear):
                return inYear
        }
    }
    
    public var isValid: Bool {
        switch self {
            case .permanent:
                return true
                
            case .periodic(let from, _, let to),
                 .spanning(let from,    let to):
                guard let fromYear = from.year, let toYear = to.year else { return false }
                return fromYear < toYear
                
            case .starting(from: _):
                return true
                
            case .ending(to: _):
                return true
                
            case .exceptional(inYear: _):
                return true
        }
    }
}

// MARK: - Extensions

extension TimeSpan: PickableIdentifiableEnumP {
    public var id: Int {
        return self.rawValue
    }
    
    public var pickerString: String {
        switch self {
            case .permanent:
                return "Permanent"
            case .periodic:
                return "Periodique"
            case .starting:
                return "Depuis..."
            case .ending:
                return "Jusqu'à..."
            case .spanning:
                return "De...à..."
            case .exceptional:
                return "Ponctuelle"
        }
    }
}

// MARK: - Extension: Description

extension TimeSpan: CustomStringConvertible {
    public var description: String {
        switch self {
            case .permanent:
                return "Permanent"
            case .periodic (let from, let period, let to):
                return
                    """

                    Periodique:
                    - de \(from) (inclus) à \(to) (exclu)
                    - tous les \(period) ans
                    """
                
            case .starting (let from):
                return "A partir de \(from) (inclus)"
                
            case .ending (let to):
                return "Jusqu'à \(to) (exclu)"
                
            case .spanning (let from, let to):
                return "De \(from) (inclus) à \(to) (exclu)"
                
            case .exceptional(let inYear):
                return "En \(inYear)"
        }
    }
}
