//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 25/07/2021.
//

import Foundation
import AppFoundation
import Persistable
import Files

/// Protocol requérant une méthode d'initialisation post-création
public protocol InitializableP {
    func initialized() -> Self
}

/// Protocol de Model persistant pouvant être initializer et enregsiter à partir.vers un fichier JSON
/// contenu soit dans un Dossier utilisateur soit dans un Bundle
public protocol PersistableModelP: PersistableP {
    associatedtype Model: InitializableP, JsonCodableToFolderP, JsonCodableToBundleP
    
    // MARK: - Static Properties
    
    static var defaultFileName : String { get }
    
    // MARK: - Properties
    
    var model         : Model? { get set }
    var persistenceSM : PersistenceStateMachine { get set }
    
    // MARK: - Initializers
    
    init()
    init(fromFolder folder: Folder) throws
    init(fromBundle bundle: Bundle)
    
    // MARK: - Methods
    
    func saveAsJSON(toFolder folder: Folder) throws
    func saveAsJSON(toBundle bundle: Bundle)
}
// default implementation
public extension PersistableModelP {
    // MARK: - Initializers
    
    init(fromFolder folder: Folder) throws {
        self.init()
        self.model =
            try Model(fromFile             : Self.defaultFileName,
                      fromFolder           : folder,
                      dateDecodingStrategy : .iso8601,
                      keyDecodingStrategy  : .useDefaultKeys)
            .initialized()
        // exécuter la transition
        self.persistenceSM.process(event: .load)
    }
    
    /// Charger le modèle à partir d'un fichier JSON contenu dans le fichier `defaultFileName`
    /// du `bundle` et l'initialiser
    /// - Parameters:
    ///   - bundle: le bundle dans lequel chercher le fichier nommé `defaultFileName`
    init(fromBundle bundle: Bundle) {
        self.init()
        self.model =
            bundle.loadFromJSON(Model.self,
                                from                 : Self.defaultFileName,
                                dateDecodingStrategy : .iso8601,
                                keyDecodingStrategy  : .useDefaultKeys)
            .initialized()
        // exécuter la transition
        self.persistenceSM.process(event: .load)
    }
    
    // MARK: - Methods
    
    /// Enregistrer le modèle au format JSON dans un fichier nommé `defaultFileName`
    /// dans le folder nommé `folder` du répertoire `Documents`
    /// - Parameters:
    ///   - folder: folder du répertoire `Documents`
    func saveAsJSON(toFolder folder: Folder) throws {
        // encode to JSON file
        try model!.saveAsJSON(toFile               : Self.defaultFileName,
                              toFolder             : folder,
                              dateEncodingStrategy : .iso8601,
                              keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }
    
    /// Enregistrer le modèle au format JSON dans un fichier nommé `defaultFileName`
    /// du `bundle` et l'initialiser
    /// - Parameters:
    ///   - bundle: le bundle dans lequel stocker le fichier nommé `defaultFileName`
    func saveAsJSON(toBundle bundle: Bundle) {
        bundle.saveAsJSON(model,
                          to                   : Self.defaultFileName,
                          dateEncodingStrategy : .iso8601,
                          keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }
}
