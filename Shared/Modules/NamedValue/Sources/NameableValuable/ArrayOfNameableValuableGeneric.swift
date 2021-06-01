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

// MARK: - Table d'Item Generic Valuable and Nameable

public struct ArrayOfNameableValuable<E>: JsonCodableToFolderP, Versionable, Persistable where
    E: Codable,
    E: Identifiable,
    E: CustomStringConvertible,
    E: NameableValuable {
    
    private enum CodingKeys: String, CodingKey {
        case version, items
    }
    
    // MARK: - Properties

    public  var items           = [E]()
    public  var version         = Version()
    private var fileNamePrefix  : String?
    public  var persistenceSM   = PersistenceStateMachine()
    
    // MARK: - Computed Properties
    
    public var currentValue    : Double {
        items.sumOfValues(atEndOf: Date.now.year)
    } // computed

    // MARK: - Subscript

    public subscript(idx: Int) -> E {
        get {
            return items[idx]
        }
        set(newValue) {
            items[idx] = newValue
        }
    }

    // MARK: - Initializers
    
    /// Initialiser à vide
    public init() {
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

        // exécuter la transition
        persistenceSM.process(event: .load)
   }
    
    public init(for aClass     : AnyClass,
                fileNamePrefix : String = "") {
        let classBundle = Bundle(for: aClass)
        self = classBundle.loadFromJSON(ArrayOfNameableValuable.self,
                                        from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix

        // exécuter la transition
        persistenceSM.process(event: .load)
    }
    
    // MARK: - Methods

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
        items.map {
            (name  : $0.name,
             value : $0.value(atEndOf : atEndOf))
        }
    }
}

extension ArrayOfNameableValuable: CustomStringConvertible {
    public var description: String {
        items.reduce("") { r, item in
            r + String(describing: item) + "\n\n"
        }
    }
}
