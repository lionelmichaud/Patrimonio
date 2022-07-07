//
//  DictionaryItemArray.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Files

// MARK: - Dictionnaire de [Category : Table d'Item Valuable and Namable]

public final class DictionaryOfNameableValuableArray <ItemCategory, ArrayOfItems>: ObservableObject
where ItemCategory: PickableEnumP,
      ItemCategory: Codable,
      ArrayOfItems: NameableValuableArrayP,
      ArrayOfItems: CustomStringConvertible {

    // MARK: - Properties

    @Published public var perCategory = [ItemCategory: ArrayOfItems]()

    // MARK: - Computed Properties
    
    public var isModified: Bool {
        var hasChanged = false
        for category in ItemCategory.allCases {
            hasChanged = hasChanged || (perCategory[category]?.isModified ?? false)
        }
        return hasChanged
    }
    
    // MARK: - Subscript
    
    public subscript(category: ItemCategory) -> ArrayOfItems? {
        get {
            return perCategory[category]
        }
        set(newValue) {
            perCategory[category] = newValue
        }
    }
    
    // MARK: - Initializers

    /// Initialiser à vide
    /// - Note: Utilisé à la création de l'App, avant que le dossier n'ait été sélectionné
    public init() {
    }
    
    /// Lire toutes les dépenses dans des fichiers au format JSON.
    /// Un fichier par catégorie de dépense.
    /// nom du fichier "Category_LifeExpense.json"
    /// - Note: Utilisé seulement pour les Tests
    /// - Parameter bundle: le bundle dans lequel se trouve les fichiers JSON
    public init(fromBundle bundle : Bundle,
                fileNamePrefix    : String = "") throws {
        for category in ItemCategory.allCases {
            // charger les Items de cette catégorie à partir du fichier JSON associé à cette catégorie
            perCategory[category] = try ArrayOfItems(fileNamePrefix : category.pickerString + "_",
                                                     fromBundle     : bundle)
        }
    }
    /// Lire toutes les dépenses dans des fichiers au format JSON.
    /// Un fichier par catégorie de dépense.
    /// nom du fichier "Category_LifeExpense.json"
    /// - Note: Utilisé seulement pour les Tests
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    /// - Throws: en cas d'échec de lecture des données
    public init(fromFolder folder: Folder) throws {
        try loadFromJSON(fromFolder: folder)
    }

    // MARK: - Methods

    /// Lire toutes les dépenses dans des fichiers au format JSON.
    /// Un fichier par catégorie de dépense.
    /// nom du fichier "Category_LifeExpense.json"
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    /// - Throws: en cas d'échec de lecture des données
    public func loadFromJSON(fromFolder folder: Folder) throws {
        for category in ItemCategory.allCases {
            // charger les Items de cette catégorie à partir du fichier JSON associé à cette catégorie
            perCategory[category] = try ArrayOfItems(fileNamePrefix : category.pickerString + "_",
                                                     fromFolder     : folder)
        }
    }
    
    // MARK: - Methods

    /// Enregistrer toutes les dépenses dans des fichiers au format JSON..
    /// Un fichier par catégorie de dépense.
    public func saveAsJSON(toFolder folder: Folder) throws {
        for category in perCategory.keys {
            // encode to JSON file
            try perCategory[category]?.saveAsJSON(fileNamePrefix : category.pickerString + "_",
                                                  toFolder       : folder)
        }
    }

    /// Somme de toutes les dépenses, toutes catégories confondues
    /// - Parameter atEndOf: année de calcul
    /// - Returns: dépenses totales
    public func value(atEndOf: Int) -> Double {
        var sum = 0.0
        perCategory.forEach { (_, expenseArray) in
            sum += expenseArray.value(atEndOf: atEndOf)
        }
        return sum
    }

    /// Liste complète à plat de toutes les dépenses valorisées, toutes catégories confondues
    /// - Parameter atEndOf: année de calcul
    /// - Returns: liste complète à plat de toutes les dépenses
    public func flatNamedValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        perCategory.forEach { (_, expenseArray) in
            table += expenseArray.namedValueTable(atEndOf: atEndOf)
        }
        return table
    }

    /// Total des dépenses valorisées  par catégorie
    /// - Parameter atEndOf: année de calcul
    /// - Returns: tableau des totaux des dépenses par catégorie
    public func namedTotalValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        for category in ItemCategory.allCases {
            if let exps = perCategory[category] {
                table.append(.init(name: category.displayString,
                                   value: exps.value(atEndOf: atEndOf)))
            }
        }
        return table
    }

    /// Dictionnaire des dépenses valorisées  par catégorie
    /// - Parameter atEndOf: année de calcul
    /// - Returns: dictionnaire des dépenses par catégorie
    public func namedValueTable(atEndOf: Int) -> [ItemCategory: NamedValueArray] {
        var dico = [ItemCategory: NamedValueArray]()
        for category in ItemCategory.allCases {
            if let exps = perCategory[category] {
                dico[category] = exps.namedValueTable(atEndOf: atEndOf)
            }
        }
        return dico
    }

    /// Liste des dépenses valorisées d'une catégorie donnée
    /// - Parameters:
    ///   - atEndOf: année de calcul
    ///   - inCategory: catégorie de dépenses à prendre
    /// - Returns: liste des dépenses de cette catégorie
    public func namedValueTable(atEndOf: Int, inCategory: ItemCategory) -> NamedValueArray {
        if let exps = perCategory[inCategory] {
            return exps.namedValueTable(atEndOf: atEndOf)
        } else {
            return []
        }
    }
}

extension DictionaryOfNameableValuableArray: CustomStringConvertible {
    public var description: String {
        var desc = ""
        perCategory.sorted(by: \.key.displayString).forEach { cat, items in
            desc += "- \(cat.displayString.uppercased()):\n"
            desc += String(describing: items)
            desc += "\n"
        }
        return desc
    }
}
