//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 03/08/2021.
//

import Foundation

// MARK: - DI: Protocol de service de fourniture de l'année d'un événement de vie d'une personne

public protocol PersonEventYearProviderP {
    func yearOf(lifeEvent : LifeEvent,
                for name  : String) -> Int?
    func yearOf(lifeEvent : LifeEvent,
                for group : GroupOfPersons,
                order     : SoonestLatest) -> Int?
}
