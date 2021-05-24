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
extension DossierArray {
    static func load() throws -> DossierArray {
        try PersistenceManager.loadUserDossiersFromDocumentsDirectory()
    }
}

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

    // le dossier en cours d'utilisation
    static var current : Dossier?

    // le dossier contenant les template à utiilser pour créer un nouveau dossier
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
    private var _isUserDossier    = true

    // MARK: - Computed Properties

    var name: String {
        get { _name ?? "Pas de nom" }
        set { _name = newValue}
    }
    var note: String {
        get { _note ?? "Pas de commentaire" }
        set { _note = newValue }
    }
    var dateCreationStr: String {
        _dateCreation.stringShortDate
    }
    private var dateModification: Date? {
        do {
            let dateModif = try PersistenceManager.getUserDirectoryLastModifiedDate(withID: self.id)
            if let dateCreation = _dateCreation {
                return max(dateCreation, dateModif)
            } else {
                return dateModif
            }
        } catch {
            return nil
        }
    }
    var dateModificationStr: String {
        if let dateModif = self.dateModification {
            return dateModif.stringShortDate
        } else {
            return "nil"
        }
    }
    var hourModificationStr: String {
        if let dateModif = self.dateModification {
            return dateModif.stringTime
        } else {
            return "nil"
        }
    }
    var folderName : String { folder?.name ?? "No folder" }

    // MARK: - Initializer

    init(id                          : UUID     = UUID(),
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

    static func create(name : String,
                       note : String) throws -> Dossier {
        let newDossier = Dossier()

        // créer le directory associé
        let targetFolder = try PersistenceManager.newUserDirectory(withID: newDossier.id)

        // initialiser las propriétés
        return
            newDossier
            .pointingTo(targetFolder)
            .namedAs(name)
            .annotatedBy(note)
            .createdOn(Date.now)
            .ownedByUser()
    }

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

    func duplicate() throws -> Dossier {
        let newDossier = Dossier()

        // créer le directory associé
        let targetFolder = try PersistenceManager.newUserDirectory(withID: newDossier.id,
                                                                   withContentDuplicatedFrom: folder)

        // initialiser las propriétés
        return
            newDossier
            .pointingTo(targetFolder)
            .namedAs(name + "-copie")
            .annotatedBy(note)
            .createdOn(Date.now)
            .ownedByUser()
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
