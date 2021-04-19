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
struct DateBoundary: Hashable, Codable {
    
    // MARK: - Static Properties
    
    static var personEventYearProvider: PersonEventYearProvider!
    static let empty: DateBoundary = DateBoundary()
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    static func setPersonEventYearProvider(_ personEventYearProvider : PersonEventYearProvider) {
        DateBoundary.personEventYearProvider = personEventYearProvider
    }
    
    // MARK: - Properties
    
    // date fixe ou calculée à partir d'un éventuel événement de vie d'une personne
    var fixedYear : Int = 0
    // non nil si la date est liée à un événement de vie d'une personne
    var event : LifeEvent?
    // personne associée à l'évenement
    var name  : String?
    // groupe de personnes associées à l'événement
    var group : GroupOfPersons?
    // date au plus tôt ou au plus tard du groupe
    var order : SoonestLatest?
    
    // MARK: - Computed Properties
    
    // date fixe ou calculée à partir d'un événement de vie d'une personne ou d'un groupe
    var year  : Int? {
        if let lifeEvent = self.event {
            // la borne temporelle est accrochée à un événement
            if let group = group {
                if let order = order {
                    return DateBoundary.personEventYearProvider.yearOf(lifeEvent : lifeEvent,
                                                                       for       : group,
                                                                       order     : order)
                } else {
                    return nil
                }
            } else {
                // rechercher la personne
                if let theName = name,
                   let year = DateBoundary.personEventYearProvider.yearOf(lifeEvent: lifeEvent,
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
}

extension DateBoundary: CustomStringConvertible {
    var description: String {
        if let lifeEvent = self.event {
            return "\(lifeEvent.description) de \(name ?? group?.description ?? "nil") en \(year ?? -1)"
        } else {
            return String(fixedYear)
        }
    }
}
