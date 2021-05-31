//
//  ItemArrayGeneric.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Stateful
import AppFoundation
import FileAndFolder
import Files

// MARK: - Satet Machine de gestion de la persistence

enum PersistenceEvent {
    case load
    case modify
    case save
}

public enum PersistenceState: String {
    case created  = "Créé"
    case synced   = "Synchronisé"
    case modified = "Modifié"
}

typealias PersistenceTransition   = Transition<PersistenceState, PersistenceEvent>
typealias PersistenceStateMachine = StateMachine<PersistenceState, PersistenceEvent>

// MARK: - Table d'Item Generic Valuable and Nameable

public struct ArrayOfNameableValuable<E>: JsonCodableToFolderP, Versionable where
    E: Codable,
    E: Identifiable,
    E: CustomStringConvertible,
    E: NameableValuable {
    
    // MARK: - Properties

    private var fileNamePrefix : String?
    private var persistenceSM  = PersistenceStateMachine(initialState: .created)
    public var items           = [E]()
    public var version         = Version()
    public var currentValue    : Double {
        items.sumOfValues(atEndOf: Date.now.year)
    } // computed
    public var persistenceState: PersistenceState {
        persistenceSM.currentState
    }

    private enum CodingKeys: String, CodingKey {
        case version, items
    }

    // MARK: - Subscript

    public subscript(idx: Int) -> E {
        get {
            return  items[idx]
        }
        set(newValue) {
            items[idx] = newValue
        }
    }

    // MARK: - Initializers
    
    /// Initialiser à vide
    public init() {
        // initialiser la StateMachine
        initializeStateMachine()
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    public init(fileNamePrefix    : String = "",
                fromFolder folder : Folder) throws {

        // charger les données JSON
        try self.init(fromFile             : fileNamePrefix + String(describing: E.self) + ".json",
                      fromFolder           : folder,
                      dateDecodingStrategy : .iso8601,
                      keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix

        // initialiser la StateMachine
        initializeStateMachine()

        // exécuter la transition
        persistenceSM.process(event: .load)
   }
    
    public init(for aClass     : AnyClass,
                fileNamePrefix : String = "") {
        let bundle = Bundle(for: aClass)
        self = bundle.loadFromJSON(ArrayOfNameableValuable.self,
                                   from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                   dateDecodingStrategy : .iso8601,
                                   keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix

        // initialiser la StateMachine
        initializeStateMachine()

        // exécuter la transition
        persistenceSM.process(event: .load)
    }
    
    // MARK: - Methods

    private func initializeStateMachine() {
        // initialiser la StateMachine
        let transition1 = PersistenceTransition(with: .load, from: .created, to: .synced)
        persistenceSM.add(transition: transition1)
        let transition2 = PersistenceTransition(with: .modify, from: .synced, to: .modified)
        persistenceSM.add(transition: transition2)
        let transition3 = PersistenceTransition(with: .save, from: .modified, to: .synced)
        persistenceSM.add(transition: transition3)
        #if DEBUG
        persistenceSM.enableLogging = true
        #endif
    }
    
    public func saveAsJSON(toFolder folder: Folder) throws {
        // encode to JSON file
        try saveAsJSON(toFile               : self.fileNamePrefix! + String(describing: E.self) + ".json",
                       toFolder             : folder,
                       dateEncodingStrategy : .iso8601,
                       keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }
    
    func storeItemsToBundleOf(aClass: AnyClass) {
        let bundle = Bundle(for: aClass)
        // encode to JSON file
        bundle.saveAsJSON(self,
                          to                   : self.fileNamePrefix! + String(describing: E.self) + ".json",
                          dateEncodingStrategy : .iso8601,
                          keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }
    
    public mutating func move(from indexes   : IndexSet,
                              to destination : Int) {
        items.move(fromOffsets: indexes, toOffset: destination)
    }
    
    public mutating func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        // exécuter la transition
        persistenceSM.process(event: .modify)
    }
    
    public mutating func add(_ item: E) {
        items.append(item)
        // exécuter la transition
        persistenceSM.process(event: .modify)
    }
    
    public mutating func update(with item : E,
                                at index  : Int) {
        items[index] = item
        // exécuter la transition
        persistenceSM.process(event: .modify)
    }
    
    public func value(atEndOf: Int) -> Double {
        items.sumOfValues(atEndOf: atEndOf)
    }
    
    public func namedValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        for item in items {
            table.append((name: item.name, value: item.value(atEndOf: atEndOf)))
        }
        return table
    }
}

extension ArrayOfNameableValuable: CustomStringConvertible {
    public var description: String {
        items.reduce("") { r, item in
            r + item.description + "\n\n"
        }
    }
}
