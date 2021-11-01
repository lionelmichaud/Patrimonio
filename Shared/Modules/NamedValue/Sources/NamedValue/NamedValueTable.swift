//
//  NamedValue.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Table nommée de couples (nom, valeur)

public typealias NamedValue = (name: String, value: Double)

func == (lhs: NamedValue, rhs: NamedValue) -> Bool {
    lhs.name == rhs.name && lhs.value == rhs.value
}

func < (lhs: NamedValue, rhs: NamedValue) -> Bool {
    lhs.name < rhs.name
}

public typealias NamedValueArray = [NamedValue]

public struct NamedValueTable: HasNamedValuedTableP {
    
    // MARK: - Properties
    
    public var tableName   = ""
    public var namedValues = NamedValueArray()

    // MARK: - Initializer
    public init(tableName: String) {
        self.tableName = tableName
    }
}

extension NamedValueTable: CustomStringConvertible {
    public var description: String {
        """
        Nom de la table: \(tableName)
        Valeurs de la table:

        """
            +
            String(describing: namedValues)
    }
}

// MARK: - Protocol de Table nommée de couples (nom, valeur)

public protocol HasNamedValuedTableP {

    // MARK: - Properties
    
    // nom de la table
    var tableName   : String { get set }
    // tableau des valeurs nommées inclues dans la table nommée `tableName`
    var namedValues : NamedValueArray { get set }
    // somme des valeurs du tableau `namedValues`
    var total       : Double { get }
    var namesArray  : [String] { get }
    var valuesArray : [Double] { get }

    // MARK: - Methods
    
    func filtredNames(with itemSelectionList: ItemSelectionList) -> [String]
    
    func filtredValues(with itemSelectionList: ItemSelectionList) -> [Double]
    
    /// Retourne un tableau à un seul élément si le menu contient le nom de la table
    /// - Parameter itemSelectionList: menu
    /// - Returns: nom de la table si elle figure dans le menu
    func filtredTableName(with itemSelectionList: ItemSelectionList) -> [String]
    
    /// Retourne un tableau à un seul élément si le menu contient le nom de la table
    /// - Parameter itemSelectionList: menu
    /// - Returns: valeur cumulée des éléments de la table si elle figure dans le menu
    func filtredTableValue(with itemSelectionList: ItemSelectionList) -> [Double]

    func contains(name: String) -> Bool
}

extension HasNamedValuedTableP {
    public var total: Double {
        namedValues
            .reduce(.zero, {result, element in result + element.value})
    }
    /// tableau des noms
    public var namesArray: [String] {
        namedValues
            .map(\.name)
    }
    /// tableau des valeurs
    public var valuesArray: [Double] {
        namedValues
            .map(\.value)
    }
    
    // MARK: - Methods
    
    /// tableau des noms en ne gardant que ceux contenu dans itemSelectionList
    public func filtredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        namedValues
            .filter({ itemSelectionList.contains($0.name) })
            .map(\.name)
    }
    
    /// tableau des valeurs en ne gardant que celles dont le nomn associé est contenu dans itemSelectionList
    public func filtredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        namedValues
            .filter({ itemSelectionList.contains($0.name) })
            .map(\.value)
    }
    
    public func filtredTableName(with itemSelectionList: ItemSelectionList) -> [String] {
        if itemSelectionList.contains(tableName) {
            return [tableName]
        } else {
            return [String]()
        }
    }
    
    public func filtredTableValue(with itemSelectionList: ItemSelectionList) -> [Double] {
        if itemSelectionList.contains(tableName) {
            return [total]
        } else {
            return [Double]()
        }
    }

    public func contains(name: String) -> Bool {
        namesArray.contains(name)
    }

}
