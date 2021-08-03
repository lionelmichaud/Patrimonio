//
//  DateBoundary.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/04/2021.
//

import Foundation

// MARK: - Limite temporelle fixe ou liée à un événement de vie

/// Limite temporelle d'une dépense: début ou fin.
/// Date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
public struct DateBoundary: Hashable, Codable {
    
    // MARK: - Static Properties
    
    static var personEventYearProvider: PersonEventYearProviderP!
    public static let empty: DateBoundary = DateBoundary()
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    public static func setPersonEventYearProvider(_ personEventYearProvider : PersonEventYearProviderP) {
        DateBoundary.personEventYearProvider = personEventYearProvider
    }
    
    public static func yearOf(lifeEvent : LifeEvent,
                              for name  : String) -> Int? {
        DateBoundary.personEventYearProvider.yearOf(lifeEvent : lifeEvent,
                                                    for       : name)
    }

    public static func yearOf(lifeEvent : LifeEvent,
                              for group : GroupOfPersons,
                              order     : SoonestLatest) -> Int? {
        DateBoundary.personEventYearProvider.yearOf(lifeEvent : lifeEvent,
                                                    for       : group,
                                                    order     : order)
    }

    // MARK: - Properties
    
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    public var fixedYear : Int = 0
    // non nil si la date est liée à un événement de vie d'une personne
    public var event : LifeEvent?
    // personne associée à l'évenement
    public var name  : String?
    // groupe de personnes associées à l'événement
    public var group : GroupOfPersons?
    // date au plus tôt ou au plus tard du groupe
    public var order : SoonestLatest?
    
    // MARK: - Computed Properties
    
    // date fixe ou calculée à partir d'un événement de vie d'une personne ou d'un groupe
    public var year  : Int? {
        if let lifeEvent = self.event {
            // la borne temporelle est accrochée à un événement
            if let group = group {
                if let order = order {
                    return
                        DateBoundary
                        .personEventYearProvider
                        .yearOf(lifeEvent : lifeEvent,
                                for       : group,
                                order     : order)
                } else {
                    return nil
                }
            } else {
                // rechercher la personne
                if let theName = name,
                   let year =
                    DateBoundary
                    .personEventYearProvider
                    .yearOf(lifeEvent: lifeEvent,
                            for: theName) {
                    // rechercher l'année de l'événement pour cette personne
                    return year
                } else {
                    // on ne trouve pas le nom de la personne dans la famille
                    return nil
                }
            }
        } else {
            // pas d'événement, la date est fixe
            return fixedYear
        }
    }

    // MARK: - Initializer

    public init(fixedYear : Int              = 0,
                event     : LifeEvent?       = nil,
                name      : String?          = nil,
                group     : GroupOfPersons?  = nil,
                order     : SoonestLatest?   = nil) {
        self.fixedYear = fixedYear
        self.event     = event
        self.name      = name
        self.group     = group
        self.order     = order
    }
}

extension DateBoundary: CustomStringConvertible {
    public var description: String {
        if let lifeEvent = self.event {
            let yearString = (year == nil ? "`nil`" : String(year!))
            return "\(lifeEvent.description) de \(name ?? group?.description ?? "`nil`") en \(yearString)"
        } else {
            return String(fixedYear)
        }
    }
}
