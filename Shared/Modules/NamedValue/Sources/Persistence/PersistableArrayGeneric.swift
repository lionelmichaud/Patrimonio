//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 01/06/2021.
//

import Foundation
import Persistable
import AppFoundation
import FileAndFolder
import Files

public struct PersistableArray<E>: JsonCodableToFolderP, PersistableP where
    E: Codable,
    E: Identifiable,
    E: CustomStringConvertible {    
    
    private enum CodingKeys: String, CodingKey {
        case items
    }
    
    // MARK: - Properties
    
    public  var items          = [E]()
    public  var persistenceSM  = PersistenceStateMachine()
    private var fileNamePrefix : String?

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
    
    /// Initialiser à partir d'un fichier JSON portant le nom de la Class `E`
    /// préfixé par `fileNamePrefix`
    /// contenu dans le dossier `fromFolder` du répertoire `Documents`
    /// - Parameter fromFolder: dossier où se trouve le fichier JSON à utiliser
    /// - Parameter fileNamePrefix: préfixe du nom de fichier
    public init(fileNamePrefix    : String = "",
                fromFolder folder : Folder) throws {
        
        // charger les données JSON
        try self.init(fromFile             : fileNamePrefix + String(describing: E.self) + ".json",
                      fromFolder           : folder,
                      dateDecodingStrategy : .iso8601,
                      keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    public init(for aClass     : AnyClass,
                fileNamePrefix : String = "") {
        let classBundle = Bundle(for: aClass)
        self = classBundle.loadFromJSON(PersistableArray.self,
                                        from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    // MARK: - Methods
    
    /// Enregistrer au format JSON dans un fichier JSON portant le nom de la Class `E`
    /// préfixé par `self.fileNamePrefix`
    /// dans le folder nommé `toFolder` du répertoire `Documents`
    /// - Parameters:
    ///   - toFolder: nom du dossier du répertoire `Documents`
    public func saveAsJSON(toFolder folder: Folder) throws {
        // encode to JSON file
        try saveAsJSON(toFile               : self.fileNamePrefix! + String(describing: E.self) + ".json",
                       toFolder             : folder,
                       dateEncodingStrategy : .iso8601,
                       keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .onSave)
    }
    
    func storeItemsToBundleOf(aClass: AnyClass) {
        let bundle = Bundle(for: aClass)
        // encode to JSON file
        bundle.saveAsJSON(self,
                          to                   : self.fileNamePrefix! + String(describing: E.self) + ".json",
                          dateEncodingStrategy : .iso8601,
                          keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .onSave)
    }
    
    public mutating func move(from indexes   : IndexSet,
                              to destination : Int) {
        items.move(fromOffsets: indexes, toOffset: destination)
    }
    
    public mutating func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        // exécuter la transition
        persistenceSM.process(event: .onModify)
    }
    
    public mutating func add(_ item: E) {
        items.append(item)
        // exécuter la transition
        persistenceSM.process(event: .onModify)
    }
    
    public mutating func update(with item : E,
                                at index  : Int) {
        items[index] = item
        // exécuter la transition
        persistenceSM.process(event: .onModify)
    }
}
