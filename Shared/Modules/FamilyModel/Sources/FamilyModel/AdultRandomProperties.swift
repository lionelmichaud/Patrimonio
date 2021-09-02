//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 02/09/2021.
//

import Foundation

// MARK: - Propriétés aléatoires d'un Adult

public struct AdultRandomProperties: Hashable, Codable {
    public var ageOfDeath           : Int
    public var nbOfYearOfDependency : Int
}
public typealias DictionaryOfAdultRandomProperties = [String: AdultRandomProperties]
