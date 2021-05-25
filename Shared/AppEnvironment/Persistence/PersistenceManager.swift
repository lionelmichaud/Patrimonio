//
//  Persistence.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation
import os
import Files
import Disk

private let customLog = Logger(subsystem : "me.michaud.lionel.Patrimonio",
                               category  : "PersistenceManager")

extension Folder {
    // The current Application folder
    static var application: Folder? {
        guard let resourcePath = Bundle.main.resourcePath else {
            return nil
        }
        return try? Folder(path: resourcePath)
    }
    
    // Le directory est-il un directory User ?
    var isUserFolder: Bool {
        UUID(uuidString: self.name) != nil
    }
}

enum FileError: String, Error {
    case failedToSaveCashFlowCsv           = "La sauvegarde de l'historique des bilans a échoué"
    case failedToSaveBalanceSheetCsv       = "La sauvegarde de l'historique des cash-flow a échoué"
    case failedToSaveMonteCarloCsv         = "La sauvegarde de l'historique des runs a échoué"
    case failedToSaveSuccessionsCSV        = "La sauvegarde des successions légales a échoué"
    case failedToSaveLifeInsSuccessionsCSV = "La sauvegarde des successions assurance vie a échoué"
    case failedToResolveDocuments          = "Impossible de trouver le répertoire 'Documents' de l'utilisateur"
    case failedToResolveLibrary            = "Impossible de trouver le répertoire 'Library' de l'utilisateur"
    case failedToCreateTemplateDirectory   = "Impossible de créer le répertoire 'template' dans le répertoire 'Library' de l'utilisateur"
    case directoryToDuplicateDoesNotExist  = "Le répertoire à dupliquer n'est pas défini"
    case failedToDuplicateTemplates        = "Echec de la copie des templates"
    case templatesDossierNotInitialized    = "Dossier 'templates' non initializé"
    case failedToImportTemplates           = "Echec de l'importation des templates depuis Bundle.Main vers 'Library'"
}

struct PersistenceManager {
    
    // MARK: - Static Methods
    
    static func saveDescriptor(of dossier: Dossier) throws {
        let dossierDescriptorFile = try dossier.folder?.createFileIfNeeded(withName: "AppDescriptor.json")
        dossierDescriptorFile?.saveAsJSON(dossier, dateEncodingStrategy: .iso8601)
    }
    
    /// Dupliquer tous les fichiers JSON ne commencant pas par 'App'
    /// et présents dans le répertoire "originFolder'
    /// vers le répertoire 'targetFolder'
    /// - Parameters:
    ///   - originFolder: répertoire source
    ///   - targetFolder: répertoire destination
    /// - Throws:
    fileprivate static func duplicateTemplateFiles(from originFolder : Folder,
                                                   to targetFolder   : Folder) throws {
        do {
            try originFolder.files.forEach { file in
                if let ext = file.extension {
                    if ext == "json" && !file.name.hasPrefix("App") {
                        if !targetFolder.containsFile(named: file.name) {
                            try file.copy(to: targetFolder)
                        }
                    }
                }
            }
        } catch {
            customLog.log(level: .fault,
                          "\(FileError.failedToDuplicateTemplates.rawValue) de \(originFolder.name) vers \(targetFolder.name)")
        }
    }
    
    /// Construire la liste des dossiers en parcourant le directory "Documents"
    /// - Throws: FileError.failedToResolveDocuments
    /// - Returns: Tableau de dossier
    static func loadUserDossiers() throws -> DossierArray {
        /// rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            customLog.log(level: .error,
                          "\(FileError.failedToResolveDocuments.rawValue)")
            throw FileError.failedToResolveDocuments
        }
        
        // itérer sur tous les directory présents dans le directory 'Documents'
        var dossiers = DossierArray()
        documentsFolder.subfolders.forEach { folder in
            if folder.isUserFolder {
                let dossier = Dossier()
                    .identifiedBy(UUID(uuidString: folder.name)!)
                    .pointingTo(folder)
                    // TODO: - compléter: récupérer le nom du Dossier dans un des fichiers du directory
                    .namedAs(folder.name.uppercased())
                    .ownedByUser()
                dossiers.append(dossier)
            }
        }
        
        return dossiers
    }
    
    /// Créer un nouveau répertoire nommé 'withID' dans le répertoire 'Documents'
    /// et y copier tous les templates présents dans le répertoire 'Library/template'
    /// - Parameter withID: nom du répertoire à créer
    /// - Throws:
    ///     - FileError.failedToResolveDocuments
    ///     - FileError.templatesDossierNotInitialized
    /// - Returns: répertoire créé
    static func newUserFolder(withID id: UUID) throws -> Folder {
        /// rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            customLog.log(level: .error,
                          "\(FileError.failedToResolveDocuments.rawValue)")
            throw FileError.failedToResolveDocuments
        }
        
        // créer le directory USER pour le nouveau Dossier
        let targetFolder: Folder
        targetFolder = try documentsFolder.createSubfolder(named: id.uuidString)
        
        // récupérer le dossier 'templates'
        guard let originFolder = Dossier.templates?.folder else {
            customLog.log(level: .error,
                          "\(FileError.templatesDossierNotInitialized.rawValue)")
            throw FileError.templatesDossierNotInitialized
        }
        
        // y dupliquer les fichiers du directory originFolder
        do {
            try duplicateTemplateFiles(from: originFolder, to: targetFolder)
        } catch {
            // détruire le directory créé
            try targetFolder.delete()
            throw error
        }
        
        return targetFolder
    }
    
    /// Créer un nouveau répertoire nommé 'withID' dans le répertoire 'Documents'
    /// et y copier tous les fichiers présents dans le répertoire à dupliquer
    /// - Parameters:
    ///   - id: nom du répertoire à créer
    ///   - originFolder: répertoire à dupliquer
    /// - Throws:
    ///   - FileError.failedToResolveDocuments
    ///   - FileError.directoryToDuplicateDoesNotExist
    /// - Returns: répertoire créé
    static func newUserFolder(withID id: UUID,
                              withContentDuplicatedFrom originFolder: Folder?) throws -> Folder {
        /// rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            customLog.log(level: .error,
                          "\(FileError.failedToResolveDocuments.rawValue)")
            throw FileError.failedToResolveDocuments
        }
        
        // créer le directory USER pour le nouveau Dossier
        let targetFolder: Folder
        targetFolder = try documentsFolder.createSubfolder(named: id.uuidString)
        
        // récupérer le dossier à dupliquer
        guard let originFolder = originFolder else {
            customLog.log(level: .error,
                          "\(FileError.directoryToDuplicateDoesNotExist.rawValue)")
            throw FileError.directoryToDuplicateDoesNotExist
        }
        
        // y dupliquer les fichiers du directory originFolder
        do {
            try duplicateTemplateFiles(from: originFolder, to: targetFolder)
        } catch {
            // détruire le directory créé
            try targetFolder.delete()
            throw error
        }
        
        return targetFolder
    }
    
    /// Détruire le répertoire portant le nom 'folderName'
    /// et situé dans le répertoire 'Documents'
    /// - Parameter folderName: nom du répertoire à détruire
    /// - Throws: FileError.failedToResolveDocuments
    static func deleteUserFolder(folderName: String) throws {
        /// rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            customLog.log(level: .error,
                          "\(FileError.failedToResolveDocuments.rawValue)")
            throw FileError.failedToResolveDocuments
        }
        
        // trouver le directory à détruire
        let targetFolder = try documentsFolder.subfolder(named: folderName)
        
        // détruire le directory
        try targetFolder.delete()
    }
    
    /// Retourne un Dossier pointant sur le directory contenant les templates
    /// Créer le directorty au besoin
    /// - Returns: Dossier pointant sur le directory contenant les templates ou 'nil' si le dossier n'est pas trouvé
    fileprivate static func getTemplateDossier() -> Folder? {
        /// rechercher le dossier 'Library' de l'utilisateur
        guard let libraryFolder = Folder.library else {
            customLog.log(level: .fault,
                          "\(FileError.failedToResolveLibrary.rawValue)")
            return nil
        }
        
        /// vérifier l'existence du directory 'templates' dans le directory 'Library' et le créer sinon
        let templateDirPath = AppSettings.shared.templatePath()
        let templateFolder = try? libraryFolder.createSubfolderIfNeeded(at: templateDirPath)
        guard templateFolder != nil else {
            // la création à échouée
            customLog.log(level: .fault,
                          "\(FileError.failedToCreateTemplateDirectory.rawValue)")
            return nil
        }
        
        return templateFolder
    }
    
    /// Importer les fichiers vierges depuis le Bundle Main de l'Application
    /// - Returns: le dossier inchangé si l'import a réussi, 'nil' sinon
    static func importTemplatesFromApp() -> Dossier? {
        guard let originFolder = Folder.application else {
            customLog.log(level: .fault,
                          "\(DossierError.failedToResolveAppBundle.rawValue))")
            return nil
        }
        
        guard let templateFolder = PersistenceManager.getTemplateDossier() else {
            return nil
        }
        
        do {
            try PersistenceManager.duplicateTemplateFiles(from: originFolder, to: templateFolder)
        } catch {
            customLog.log(level: .fault,
                          "\(FileError.failedToImportTemplates.rawValue))")
            return nil
        }
        
        return
            Dossier()
            .pointingTo(templateFolder)
            .namedAs(templateFolder.name)
            .ownedByApp()
    }
    
    /// Calculer la date de dernière modification d'un dossier utilisateur comme étant celle
    /// du fichier modifié le plus tardivement
    /// - Parameter id: UUID du dossier utilisateur
    /// - Returns: date de dernière modification d'un dossier utilisateur
    static func userFolderLastModifiedDate(withID id: UUID) throws -> Date {
        /// rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            customLog.log(level: .error,
                          "\(FileError.failedToResolveDocuments.rawValue)")
            throw FileError.failedToResolveDocuments
        }
        
        // trouver le directory demandé
        let targetFolder = try documentsFolder.subfolder(named: id.uuidString)
        
        // calculer la date au plus tard
        var date = 100.years.ago!
        targetFolder.files.recursive.forEach { file in
            if let modifDate = file.modificationDate {
                date = max(date, modifDate)
            }
        }
        
        return date
    }
    
    /// Sauvegarder le fichier dans un répertoire spécifique à la simulation + au fichiers au format CSV
    /// - Parameters:
    ///   - simulationTitle: nom de ls simulation utilisé pour générer le nom du répertoire
    ///   - csvString: String au format CSV à enregistrer
    ///   - fileName: nom du fichier à créer
    /// - Throws: <#description#>
    static func saveToCsvPath(simulationTitle : String,
                              fileName        : String,
                              csvString       : String) throws {
        #if DEBUG
        print(csvString)
        /// sauvegarder le fichier dans le répertoire Bundle.main
        if let fileUrl = Bundle.main.url(forResource   : fileName,
                                         withExtension : nil) {
            do {
                try csvString.write(to         : fileUrl,
                                    atomically : true,
                                    encoding   : .utf8)
            } catch let error as NSError {
                customLog.log(level: .fault,
                              "Fault saving \(fileName, privacy: .public) to: \(fileUrl.path + fileName, privacy: .public)")
                fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
            }
        } else {
            customLog.log(level: .fault,
                          "Fault saving \(fileName, privacy: .public) : file not found")
        }
        #endif
        
        /// sauvegarder le fichier dans le répertoire: data/Containers/Data/Application/xxx/Documents/simulationTitle/csv/
        do {
            try Disk.save(Data(csvString.utf8),
                          to: .documents,
                          as: AppSettings.shared.csvPath(simulationTitle) + fileName)
            customLog.log(level: .info,
                          "Saving \(fileName, privacy: .public) to: \(Disk.Directory.documents.pathDescription + "/" + AppSettings.shared.csvPath(simulationTitle) + fileName, privacy: .public)")
        } catch let error as NSError {
            customLog.log(level: .fault,
                          "Fault saving \(fileName, privacy: .public) to: \(Disk.Directory.documents.pathDescription + "/" + AppSettings.shared.csvPath(simulationTitle) + fileName, privacy: .public)")
            print("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
            throw error
        }
    }
}
