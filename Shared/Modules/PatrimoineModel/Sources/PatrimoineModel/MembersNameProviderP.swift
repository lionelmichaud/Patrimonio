//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 02/09/2021.
//

import Foundation
import PersonModel

// MARK: - DI: Protocol de service de fourniture de la liste des noms des membres de la famille

public protocol MembersNameProviderP {
    var membersName  : [String] { get }
    var adultsName   : [String] { get }
    var childrenName : [String] { get }

    func childrenAliveName(atEndOf year: Int) -> [String]?
}

public protocol MembersProviderP {
    var members: PersistableArrayOfPerson { get }

    func member(withName name: String) -> Person?
}
