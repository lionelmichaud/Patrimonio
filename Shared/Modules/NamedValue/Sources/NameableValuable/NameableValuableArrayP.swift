//
//  Protocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Persistable
import FileAndFolder
import Files

// MARK: Protocol d'Item Valuable et Nameable

public protocol NameableValuableP {
    var name: String { get }
    func value(atEndOf year: Int) -> Double
}

// MARK: - Extensions de Array

public extension Array where Element: NameableValuableP {
    /// Somme de toutes les valeurs d'un Array
    ///
    /// Usage:
    ///
    ///     total = items.sumOfValues(atEndOf: 2020)
    ///
    /// - Returns: Somme de toutes les valeurs d'un Array
    func sumOfValues (atEndOf year: Int) -> Double {
        return reduce(.zero, {result, element in
            result + element.value(atEndOf: year)
        })
    }
}

// MARK: - Protocol Table d'Item Valuable and Nameable

// utilisé uniquement par LifeExpense
// les autres utilisent le generic ArrayOfNameableValuable
public protocol NameableValuableArrayP: JsonCodableToFolderP, PersistableP {
    associatedtype Item: Codable, Identifiable, NameableValuableP
    
    // MARK: - Properties
    
    var items            : [Item] { get set }
    var persistenceSM    : PersistenceStateMachine { get set }
    var persistenceState : PersistenceState { get }
    var currentValue     : Double { get }

    // MARK: - Subscript
    
    subscript(idx: Int) -> Item { get set }
    
    // MARK: - Initializers
    
    /// Initialiser à partir d'un fichier JSON portant le nom de la Class `Item`
    /// préfixé par `fileNamePrefix`
    /// contenu dans le dossier `fromFolder` du répertoire `Documents`
    /// - Parameter fromFolder: dossier où se trouve le fichier JSON à utiliser
    /// - Parameter fileNamePrefix: préfixe du nom de fichier
    init(fileNamePrefix    : String,
         fromFolder folder : Folder) throws

    // used for Unit Testing
    init(for aClass     : AnyClass,
         fileNamePrefix : String)

    // MARK: - Methods
    
    /// Enregistrer au format JSON dans un fichier JSON portant le nom de la Class `Item`
    /// préfixé par `self.fileNamePrefix`
    /// dans le folder nommé `toFolder` du répertoire `Documents`
    /// - Parameters:
    ///   - toFolder: nom du dossier du répertoire `Documents`
    func saveAsJSON(fileNamePrefix  : String,
                    toFolder folder : Folder) throws

    mutating func move(from indexes   : IndexSet,
                       to destination : Int)
    
    mutating func delete(at offsets     : IndexSet)
    
    mutating func add(_ item         : Item)
    
    mutating func update(with item      : Item,
                         at index       : Int)
    
    func value(atEndOf: Int) -> Double
    
    func namedValueTable(atEndOf: Int) -> NamedValueArray
}

// implémentation par défaut
public extension NameableValuableArrayP {

    var currentValue      : Double {
        items.sumOfValues(atEndOf : CalendarCst.thisYear)
    }
    
    init(fileNamePrefix    : String,
         fromFolder folder : Folder) throws {
        // charger les données JSON
        try self.init(fromFile             : fileNamePrefix + String(describing: Item.self) + ".json",
                      fromFolder           : folder,
                      dateDecodingStrategy : .iso8601,
                      keyDecodingStrategy  : .useDefaultKeys)

        // initialiser la StateMachine
        persistenceSM = PersistenceStateMachine()

        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }

    // used for Unit Testing
    init(for aClass     : AnyClass,
         fileNamePrefix : String) {
        let classBundle = Bundle(for: aClass)
        self = classBundle.loadFromJSON(Self.self,
                                       from                 : fileNamePrefix + String(describing: Item.self) + ".json",
                                       dateDecodingStrategy : .iso8601,
                                       keyDecodingStrategy  : .useDefaultKeys)

        // initialiser la StateMachine
        persistenceSM = PersistenceStateMachine()

        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    // used for Unit Testing
    init(fileNamePrefix    : String,
         fromBundle bundle : Bundle) throws {
        // charger les données JSON
        self = bundle.loadFromJSON(Self.self,
                                   from                 : fileNamePrefix + String(describing: Item.self) + ".json",
                                   dateDecodingStrategy : .iso8601,
                                   keyDecodingStrategy  : .useDefaultKeys)
        
        // initialiser la StateMachine
        persistenceSM = PersistenceStateMachine()
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    subscript(idx: Int) -> Item {
        get {
            precondition((items.startIndex..<items.endIndex).contains(idx), "NameableValuableArray[] : out of bounds")
            return items[idx]
        }
        set(newValue) {
            precondition((items.startIndex..<items.endIndex).contains(idx), "NameableValuableArray[] : out of bounds")
            items[idx] = newValue
        }
    }
    
    func saveAsJSON(fileNamePrefix  : String,
                    toFolder folder : Folder) throws {
        // encode to JSON file
        try saveAsJSON(toFile               : fileNamePrefix + String(describing: Item.self) + ".json",
                       toFolder             : folder,
                       dateEncodingStrategy : .iso8601,
                       keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .onSave)
    }

    mutating func move(from indexes   : IndexSet,
                       to destination : Int) {
        items.move(fromOffsets: indexes, toOffset: destination)
    }

    mutating func delete(at offsets : IndexSet) {
        items.remove(atOffsets: offsets)
        // exécuter la transition
        persistenceSM.process(event: .onModify)
    }
    
    mutating func add(_ item : Item) {
        items.append(item)
        // exécuter la transition
        persistenceSM.process(event: .onModify)
    }
    
    mutating func update(with item : Item,
                         at index  : Int) {
        items[index] = item
        // exécuter la transition
        persistenceSM.process(event: .onModify)
    }
    
    func value(atEndOf: Int) -> Double {
        items.sumOfValues(atEndOf: atEndOf)
    }
    
    func namedValueTable(atEndOf: Int) -> NamedValueArray {
        items.map {
            NamedValue(name  : $0.name,
             value : $0.value(atEndOf : atEndOf))
        }
    }    
}
