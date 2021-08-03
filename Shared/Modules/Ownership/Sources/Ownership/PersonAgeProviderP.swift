//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 03/08/2021.
//

import Foundation

// MARK: - DI: Protocol de service de fourniture de l'age d'une personne

public protocol PersonAgeProviderP {
    func ageOf(_ name: String, _ year: Int) -> Int
}
