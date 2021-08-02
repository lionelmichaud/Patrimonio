//
//  Dossier.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import Foundation
import os
import AppFoundation
import FileAndFolder
import Files

private let customLog = Logger(subsystem : "me.michaud.lionel.Patrimonio",
                               category  : "Dossier")

// MARK: - Liste de DOSSIERs contenant tous les fichiers d'entrée et de sortie

public typealias DossierArray = [Dossier]
extension DossierArray {
    public mutating func load() throws {
        self = DossierArray()
        try PersistenceManager.forEachUserFolder { folder in
            let decodedDossier = try Dossier(fromFile             : FileNameCst.kDossierDescriptorFileName,
                                             fromFolder           : folder,
                                             dateDecodingStrategy : .iso8601)
            let dossier = decodedDossier
                .identifiedBy(UUID(uuidString: folder.name)!)
                .pointingTo(folder)
                .ownedByUser()
            self.append(dossier)
        }
    }
}

// MARK: - DOSSIER contenant tous les fichiers d'entrée et de sortie

public enum DossierError: String, Error {
    case failedToDeleteDossier         = "Impossible de supprimer le Dossier"
    case failedToFindFolder            = "Impossible de trouver le répertoire associé au Dossier"
    case failedToSaveDossierDescriptor = "Echec de l'enregistrement du descripteur de dossier"
    case failedToSaveDossierContent    = "Echec de l'enregistrement du contenu du dossier"
    case failedToLoadDossierContent    = "Echec du chargement du contenu du dossier"
    case inconsistencyOwnerFolderName  = "Incohérence entre le nom du directory et le type de propriétaire du Dossier"
}

public struct Dossier: JsonCodableToFolderP, Identifiable, Equatable {
    
    // MARK: - Static Properties
    
    private static let defaultFileName = FileNameCst.kDossierDescriptorFileName
    
    // le dossier contenant les template à utiilser pour créer un nouveau dossier
    public static let templates : Dossier? = {
        do {
            let templateFolder = try PersistenceManager.importTemplatesFromApp()
            return Dossier()
                .pointingTo(templateFolder)
                .namedAs(templateFolder.name)
                .ownedByApp()
        } catch {
            return nil
        }
    }()
    
    // MARK: - Properties
    
    public var id                      = UUID()
    public var folder                  : Folder?
    public var isActive                = false
    private var _name           : String?
    private var _note           : String?
    private var _dateCreation   : Date?
    private var _isUserDossier  = true

    // MARK: - Computed Properties
    
    public var name: String {
        get { _name ?? "nil" }
        set { _name = newValue}
    }
    public var note: String {
        get { _note ?? "" }
        set { _note = newValue }
    }
    public var dateCreationStr: String {
        _dateCreation.stringShortDate
    }
    private var dateModification: Date? {
        do {
            let dateModif = try PersistenceManager.userFolderLastModifiedDate(withID: self.id)
            if let dateCreation = _dateCreation {
                return max(dateCreation, dateModif)
            } else {
                return dateModif
            }
        } catch {
            return nil
        }
    }
    public var dateModificationStr: String {
        if let dateModif = self.dateModification {
            return dateModif.stringShortDate
        } else {
            return "nil"
        }
    }
    public var hourModificationStr: String {
        if let dateModif = self.dateModification {
            return dateModif.stringTime
        } else {
            return "nil"
        }
    }
    public var folderName : String { folder?.name ?? "No folder" }
    
    // MARK: - Initializers
    
    public init(id                          : UUID     = UUID(),
                pointingTo folder           : Folder?  = nil,
                with name                   : String?  = nil,
                annotatedBy note            : String?  = nil,
                createdOn dateCreation      : Date?    = nil,
                isUserDossier               : Bool     = true) {
        self.id                = id
        self.folder            = folder
        self._dateCreation     = dateCreation
        self._note             = note
        self._name             = name
        self._isUserDossier    = isUserDossier
    }
        
    /// Créer un nouveau Dossier et l'enregistrer dans le répertoire `Documents`
    /// - Parameters:
    ///   - name: nom du nouveau Dossier
    ///   - note: note du nouveau Dossier
    public init(name : String,
                note : String) throws {
        let newID = UUID()
        
        // créer le directory associé
        let targetFolder = try PersistenceManager.newUserFolder(withID: newID)
        
        // initialiser les propriétés
        self.init(id            : newID,
                  pointingTo    : targetFolder,
                  with          : name,
                  annotatedBy   : note,
                  createdOn     : Date.now,
                  isUserDossier : true)
        
        // enregistrer les propriétés du Dossier dans le répertoire associé au Dossier
        do {
            try saveAsJSON(toFile               : Dossier.defaultFileName,
                           toFolder             : targetFolder,
                           dateEncodingStrategy : .iso8601)
        } catch {
            try targetFolder.delete()
            throw error
        }
    }
        
    // MARK: - Builder methods
    
    public func identifiedBy(_ id: UUID) -> Dossier {
        var _dossier = self
        _dossier.id = id
        return _dossier
    }
    
    public func pointingTo(_ folder: Folder) -> Dossier {
        var _dossier = self
        _dossier.folder = folder
        return _dossier
    }
    
    public func namedAs(_ name: String) -> Dossier {
        var _dossier = self
        _dossier._name = name
        return _dossier
    }
    
    public func createdOn(_ date: Date = Date.now) -> Dossier {
        var _dossier = self
        _dossier._dateCreation = date
        return _dossier
    }
    
    public func annotatedBy(_ note: String) -> Dossier {
        var _dossier = self
        _dossier._note = note
        return _dossier
    }
    
    public func ownedByUser() -> Dossier {
        var _dossier = self
        _dossier._isUserDossier = true
        return _dossier
    }
    
    public func ownedByApp() -> Dossier {
        var _dossier = self
        _dossier._isUserDossier = false
        return _dossier
    }
    
    public func activated() -> Dossier {
        var _dossier = self
        _dossier.isActive = true
        return _dossier
    }
    
    public func deActivated() -> Dossier {
        var _dossier = self
        _dossier.isActive = false
        return _dossier
    }
    
    // MARK: - Methods
    
    /// Clone un Dossier et retourne le clone
    /// - Returns: le clone du Dossier dupliqué
    func duplicate() throws -> Dossier {
        let newID = UUID()
        
        // créer le directory associé
        let targetFolder = try PersistenceManager.newUserFolder(withID: newID,
                                                                withContentDuplicatedFrom: folder)
        
        // initialiser les propriétés de la copie
        let newDossier = Dossier()
            .identifiedBy(newID)
            .pointingTo(targetFolder)
            .namedAs(name + "-copie")
            .annotatedBy(note)
            .createdOn(Date.now)
            .ownedByUser()
        
        // enregistrer les propriétés du Dossier dans le répertoire associé au Dossier clone
        do {
            try newDossier.saveAsJSON()
            return newDossier
        } catch {
            try targetFolder.delete()
            throw error
        }
    }

    /// Enregistrer le descripteur de Dossier
    public func saveAsJSON() throws {
        try saveAsJSON(toFile               : Dossier.defaultFileName,
                       toFolder             : self.folder!,
                       dateEncodingStrategy : .iso8601)
    }

    /// Enregistrer le contenu du Dossier
    /// - Parameter saveDossierContentTo: closure
    public func saveDossierContentAsJSON(saveDossierContentTo: (Folder) throws -> Void) throws {
        // vérifier l'existence du Folder associé au Dossier
        guard let folder = self.folder else {
            customLog.log(level: .error,
                          "\(DossierError.failedToFindFolder.rawValue)")
            throw DossierError.failedToFindFolder
        }

        // enregistrer le desscripteur du Dossier
        do {
            try self.saveAsJSON()
        } catch {
            customLog.log(level: .error,
                          "\(DossierError.failedToSaveDossierDescriptor.rawValue)")
            throw DossierError.failedToSaveDossierDescriptor
        }

        // enregistrer les données utilisateur depuis le Dossier
        do {
            try saveDossierContentTo(folder)
        } catch {
            customLog.log(level: .error,
                          "\(DossierError.failedToSaveDossierContent.rawValue)")
            throw DossierError.failedToSaveDossierContent
        }
    }

    /// Charger le contenu du Dossier
    /// - Parameter loadDossierContentTo: closure
    public func loadDossierContentAsJSON(loadDossierContentFrom: (Folder) throws -> Void) throws {
        // vérifier l'existence du Folder associé au Dossier
        guard let folder = self.folder else {
            customLog.log(level: .error,
                          "\(DossierError.failedToFindFolder.rawValue)")
            throw DossierError.failedToFindFolder
        }

        // charger les données utilisateur depuis le Dossier
        do {
            try loadDossierContentFrom(folder)
        } catch {
            customLog.log(level: .error,
                          "\(DossierError.failedToLoadDossierContent.rawValue)")
            throw DossierError.failedToLoadDossierContent
        }
    }

    /// Supprimer le contenu du directory et le dossier associé
    /// - Throws: DossierError.failedToDeleteDossier
    public func delete() throws {
        do {
            if let folder = self.folder {
                try PersistenceManager.deleteUserFolder(folderName: folder.name)
            }
        } catch {
            customLog.log(level: .error,
                          "\(DossierError.failedToDeleteDossier.rawValue) \(_name ?? "No name")")
            throw DossierError.failedToDeleteDossier
        }
    }
}

extension Dossier: CustomStringConvertible {
    public var description: String {
        return
            """
            Dossier: \(name)
            Note:    \(note)
            Folder : \(folder?.description ?? "No folder")

            """
    }
}

extension Dossier: Codable {
    private enum CodingKeys: String, CodingKey {
        case _name          = "name"
        case _note          = "note"
        case _dateCreation  = "date de création"
        case _isUserDossier = "dossier utilisateur"
    }
}
