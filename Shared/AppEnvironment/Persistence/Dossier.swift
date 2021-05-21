//
//  Dossier.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import Foundation
import os
import AppFoundation
import Files

private let customLog = Logger(subsystem : "me.michaud.lionel.Patrimonio",
                               category  : "Dossier")

// MARK: - Liste de DOSSIERs contenant tous les fichiers d'entrée et de sortie

typealias DossierArray = [Dossier]

// MARK: - DOSSIER contenant tous les fichiers d'entrée et de sortie

enum DossierError: String, Error {
    case failedToImportTemplates      = "Echec de l'importation des templates depuis Bundle.Main vers 'Library'"
    case failedToResolveAppBundle     = "Failed to resolve App Bundle"
    case failedToDeleteDossier        = "Failed to delete Dossier"
    case noTargetFolder               = "Pas de dossier de destination"
    case inconsistencyOwnerFolderName = "Incohérence entre le nom du directory et le type de propriétaire du Dossier"
}

enum DossierCreationActionEnum: String, PickableEnum {
    case new = "Nouveau"
    case copy = "Copie de..."
    public var pickerString: String {
        return self.rawValue
    }
}

struct Dossier: Identifiable {

    // MARK: - Static Properties

    static var current   : Dossier?
    static let templates : Dossier? =
        PersistenceManager
        .getTemplateDossier()?
        .importTemplatesFromApp()

    // MARK: - Properties

    var id                        = UUID()
    var folder                    : Folder?
    private var _name             : String?
    private var _note             : String?
    private var _dateCreation     : Date?
    private var _dateModification : Date?
    private var _isUserDossier    = true

    // MARK: - Computed Properties

    var name: String {
        get { _name ?? "No name" }
        set { _name = newValue}
    }
    var note: String {
        get { _note ?? "No comment" }
        set { _note = newValue }
    }
    var dateCreation: String {
        _dateCreation.stringShortDate
    }
    var dateModification: String {
        _dateModification.stringShortDate
    }
    var folderName : String { folder?.name ?? "No folder" }

    // MARK: - Initializer

    init(id                          : UUID     = UUID(),
         pointingTo folder           : Folder?  = nil,
         with name                   : String?  = nil,
         annotatedBy note            : String?  = nil,
         createdOn dateCreation      : Date?    = nil,
         modifiedOn dateModification : Date?    = nil,
         isUserDossier               : Bool     = true) {
        self.id                = id
        self.folder            = folder
        self._dateCreation     = dateCreation
        self._dateModification = dateModification
        self._note             = note
        self._name             = name
        self._isUserDossier    = isUserDossier
    }

    static func create(name : String,
                       note : String) throws -> Dossier {
        // créer le directory associé
        let newDossier = Dossier()
        let targetFolder = try PersistenceManager.newUserDirectory(withID: newDossier.id)

        // initialiser las propriétés
        return
            newDossier
            .pointingTo(targetFolder)
            .namedAs(name)
            .annotatedBy(note)
            .createdOn(Date.now)
            .modifiedOn(Date.now)
            .ownedByUser()
    }

//    init?(pointingTo folder : Folder,
//          isUserDossier     : Bool = true) {
//
//        // a-t-on affaire à une Dossier utilisateur ?
//        if isUserDossier, let folderUUID = UUID(uuidString: folder.name) {
//            // le répertoire porte un nom de type UUID -> l'affecter au UUID du Dossier
//            self.id = folderUUID
//            self._name = folder.name
//            self.folder = folder
//
//            // a-t-on affaire à une Dossier appli ?
//        } else if !isUserDossier && folder.isUserFolder {
//            self._name = folder.name
//            self.folder = folder
//
//        } else {
//            // le nom du directory est invalide
//            customLog.log(level: .error,
//                          "\(DossierError.inconsistencyOwnerFolderName.rawValue): \(isUserDossier ? "User" : "App")")
//            return nil
//        }
//    }

    // MARK: - Builder methods

    func identifiedBy(_ id: UUID) -> Dossier {
        var _dossier = self
        _dossier.id = id
        return _dossier
    }

   func pointingTo(_ folder: Folder) -> Dossier {
        var _dossier = self
        _dossier.folder = folder
        return _dossier
    }
    
    func namedAs(_ name: String) -> Dossier {
        var _dossier = self
        _dossier._name = name
        return _dossier
    }

    func createdOn(_ date: Date = Date.now) -> Dossier {
        var _dossier = self
        _dossier._dateCreation = date
        return _dossier
    }

    func modifiedOn(_ date: Date = Date.now) -> Dossier {
        var _dossier = self
        _dossier._dateModification = date
        return _dossier
    }

    func annotatedBy(_ note: String) -> Dossier {
        var _dossier = self
        _dossier._note = note
        return _dossier
    }

    func ownedByUser() -> Dossier {
        var _dossier = self
        _dossier._isUserDossier = true
        return _dossier
    }

    func ownedByApp() -> Dossier {
        var _dossier = self
        _dossier._isUserDossier = false
        return _dossier
    }

    // MARK: - Methods

    /// Importer les fichiers vierges depuis le Bundle Main de l'Application
    /// - Returns: le dossier inchangé si l'import a réussi, 'nil' sinon
    func importTemplatesFromApp() -> Dossier? {
        guard let originFolder = Folder.application else {
            customLog.log(level: .fault,
                          "\(DossierError.failedToResolveAppBundle.rawValue))")
            return nil
        }

        guard let targetFolder = self.folder else {
            customLog.log(level: .fault,
                          "\(DossierError.noTargetFolder.rawValue))")
            return nil
        }

        do {
            try PersistenceManager.duplicateTemplateFiles(from: originFolder, to: targetFolder)
        } catch {
            customLog.log(level: .fault,
                          "\(DossierError.failedToImportTemplates.rawValue))")
            return nil
        }

        return self
    }

    /// Supprimer le contenu du directory et le dossier associé
    /// - Throws: DossierError.failedToDeleteDossier
    func delete() throws {
        do {
            if let folder = self.folder {
                try PersistenceManager.deleteUserDirectoryFromDocumentsDirectory(folderName: folder.name)
            }
        } catch {
            customLog.log(level: .error,
                          "\(DossierError.failedToDeleteDossier.rawValue) \(_name ?? "No name")")
            throw DossierError.failedToDeleteDossier
        }
    }
}

extension Dossier: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.folder == rhs.folder
    }
}

extension Dossier: CustomStringConvertible {
    var description: String {
        return
            """
            Dossier: \(name)
            Note: \(note)
            Folder : \(folder?.description ?? "No folder")

            """
    }
}
