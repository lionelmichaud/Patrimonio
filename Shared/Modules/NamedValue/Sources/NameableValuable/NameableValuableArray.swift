//
//  Protocols.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FileAndFolder
import Files

// MARK: Protocol d'Item Valuable et Nameable

public protocol NameableValuable {
    var name: String { get }
    func value(atEndOf year: Int) -> Double
}

// MARK: - Extensions de Array

public extension Array where Element: NameableValuable {
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
public protocol NameableValuableArray: JsonCodableToFolderP {
    associatedtype Item: Codable, Identifiable, NameableValuable
    
    // MARK: - Properties
    
    var items            : [Item] { get set }
    var persistenceSM    : PersistenceStateMachine { get set }
    var persistenceState : PersistenceState { get }
    var currentValue     : Double { get }

    // MARK: - Subscript
    
    subscript(idx: Int) -> Item { get set }
    
    // MARK: - Initializers
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    init(fileNamePrefix    : String,
         fromFolder folder : Folder) throws

    // used for Unit Testing
    init(for aClass     : AnyClass,
         fileNamePrefix : String)

    // MARK: - Methods
    
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
public extension NameableValuableArray {

    var persistenceState: PersistenceState {
        persistenceSM.currentState
    }

    var currentValue      : Double {
        items.sumOfValues(atEndOf : Date.now.year)
    }
    
    init(fileNamePrefix    : String,
         fromFolder folder : Folder) throws {
        // charger les données JSON
        try self.init(fromFile             : fileNamePrefix + String(describing: Item.self) + ".json",
                      fromFolder           : folder,
                      dateDecodingStrategy : .iso8601,
                      keyDecodingStrategy  : .useDefaultKeys)

        // initialiser la StateMachine
        initializeStateMachine()

        // exécuter la transition
        persistenceSM.process(event: .load)
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
        initializeStateMachine()

        // exécuter la transition
        persistenceSM.process(event: .load)
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
    
    /// Définir les transitions de la StateMachine de persistence
    private mutating func initializeStateMachine() {
        persistenceSM = PersistenceStateMachine(initialState: .created)

        // initialiser la StateMachine
        let transition1 = PersistenceTransition(with : .load,
                                                from : .created,
                                                to   : .synced)
        persistenceSM.add(transition: transition1)
        let transition2 = PersistenceTransition(with : .modify,
                                                from : .synced,
                                                to   : .modified)
        persistenceSM.add(transition: transition2)
        let transition3 = PersistenceTransition(with : .save,
                                                from : .modified,
                                                to   : .synced)
        persistenceSM.add(transition: transition3)
        #if DEBUG
        persistenceSM.enableLogging = true
        #endif
    }

    func saveAsJSON(fileNamePrefix  : String,
                    toFolder folder : Folder) throws {
        // encode to JSON file
        try saveAsJSON(toFile               : fileNamePrefix + String(describing: Item.self) + ".json",
                       toFolder             : folder,
                       dateEncodingStrategy : .iso8601,
                       keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }

    mutating func move(from indexes   : IndexSet,
                       to destination : Int) {
        items.move(fromOffsets: indexes, toOffset: destination)
    }

    mutating func delete(at offsets : IndexSet) {
        items.remove(atOffsets: offsets)
        // exécuter la transition
        persistenceSM.process(event: .modify)
    }
    
    mutating func add(_ item : Item) {
        items.append(item)
        // exécuter la transition
        persistenceSM.process(event: .modify)
    }
    
    mutating func update(with item : Item,
                         at index  : Int) {
        items[index] = item
        // exécuter la transition
        persistenceSM.process(event: .modify)
    }
    
    func value(atEndOf: Int) -> Double {
        items.sumOfValues(atEndOf: atEndOf)
    }
    
    func namedValueTable(atEndOf: Int) -> NamedValueArray {
        items.map {
            (name  : $0.name,
             value : $0.value(atEndOf : atEndOf))
        }
    }    
}
