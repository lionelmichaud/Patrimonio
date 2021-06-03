//
//  Persistence.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation
import os
import FileAndFolder
import NamedValue
import Files
import Charts // https://github.com/danielgindi/Charts.git

private let customLog = Logger(subsystem : "me.michaud.lionel.Patrimonio",
                               category  : "PersistenceManager")

// MARK: - Extension de Folder

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
    case failedToResolveAppBundle          = "Impossible de trouver le répertoire 'App Bundle'"
    case failedToResolveDocuments          = "Impossible de trouver le répertoire 'Documents' de l'utilisateur"
    case failedToResolveLibrary            = "Impossible de trouver le répertoire 'Library' de l'utilisateur"
    case failedToFindTemplateDirectory     = "Impossible de trouver le répertoire 'template' dans le répertoire 'Library' de l'utilisateur"
    case failedToCreateTemplateDirectory   = "Impossible de créer le répertoire 'template' dans le répertoire 'Library' de l'utilisateur"
    case directoryToDuplicateDoesNotExist  = "Le répertoire à dupliquer n'est pas défini"
    case failedToDuplicateTemplates        = "Echec de la copie des templates"
    case templatesDossierNotInitialized    = "Dossier 'templates' non initializé"
    case failedToImportTemplates           = "Echec de l'importation des templates depuis Bundle.Main vers 'Library'"
}

struct PersistenceManager {
    
    // MARK: - Static Methods
    
    /// Dupliquer tous les fichiers JSON ne commencant pas par `App`
    /// et présents dans le répertoire `originFolder`
    /// vers le répertoire `targetFolder`
    /// - Parameters:
    ///   - originFolder: répertoire source
    ///   - targetFolder: répertoire destination
    /// - Throws:`FileError.withContentDuplicatedFrom`
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
    
    /// Itérer une action `perform` sur tous les dossiers `utilisateur` du directory `Documents`
    /// - Parameter perform: action à réaliser sur chaque Folder
    /// - Throws: `FileError.failedToResolveDocuments`
    static func forEachUserFolder(perform: (Folder) throws -> Void) throws {
        /// rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            customLog.log(level: .error,
                          "\(FileError.failedToResolveDocuments.rawValue)")
            throw FileError.failedToResolveDocuments
        }
        
        // itérer sur tous les directory présents dans le directory 'Documents'
        try documentsFolder.subfolders.forEach { folder in
            if folder.isUserFolder {
                try perform(folder)
            }
        }
    }
    
    /// Créer un nouveau répertoire nommé `withID` dans le répertoire `Documents`
    /// et y copier tous les templates présents dans le répertoire `Library/template`
    /// - Parameter withID: nom du répertoire à créer
    /// - Throws:
    ///     - `FileError.failedToResolveDocuments`
    ///     - `FileError.templatesDossierNotInitialized`
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
        guard let originFolder = templateFolder() else {
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
    
    /// Créer un nouveau répertoire nommé `withID` dans le répertoire `Documents`
    /// et y copier tous les `templates` présents dans le répertoire `withContentDuplicatedFrom`
    /// - Parameters:
    ///   - id: nom du répertoire à créer
    ///   - originFolder: répertoire à dupliquer
    /// - Throws:
    ///   - `FileError.failedToResolveDocuments`
    ///   - `FileError.directoryToDuplicateDoesNotExist`
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
    
    /// Détruire le dossier `utilisateur` du directory `Documents`
    /// portant le nom `folderName`
    /// - Parameter folderName: nom du répertoire à détruire
    /// - Throws: `FileError.failedToResolveDocuments`
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
    
    /// Retourne le directory contenant les templates: dans le répertoire `Library/template`.
    /// Créer le directorty au besoin.
    /// - Returns: Folder pointant sur le directory contenant les templates ou 'nil' si le dossier n'est pas trouvé
    static func templateFolder() -> Folder? {
        /// rechercher le dossier 'Library' de l'utilisateur
        guard let libraryFolder = Folder.library else {
            customLog.log(level: .fault,
                          "\(FileError.failedToResolveLibrary.rawValue)")
            return nil
        }

        /// vérifier l'existence du directory 'templates' dans le directory 'Library' et le créer sinon
        let templateDirPath = AppSettings.shared.templatePath()
        if let templateFolder = try? libraryFolder.subfolder(at: templateDirPath) {
            return templateFolder

        } else {
            // le créer
            do {
                try libraryFolder.createSubfolder(at: templateDirPath)
                do {
                    let newTemplateFolder = try importTemplatesFromApp()
                    return newTemplateFolder
                } catch {
                    // la création a échouée
                    return nil
                }

            } catch {
                // la création à échouée
                customLog.log(level: .fault,
                              "\(FileError.failedToCreateTemplateDirectory.rawValue)")
                return nil
            }
        }
    }
    
    /// Importer les fichiers vierges depuis le `Bundle Main` de l'Application
    /// vers le répertoire `Library/template`
    /// - Returns: le dossier 'template' si l'import a réussi, 'nil' sinon
    @discardableResult
    static func importTemplatesFromApp() throws -> Folder {
        guard let originFolder = Folder.application else {
            customLog.log(level: .fault,
                          "\(FileError.failedToResolveAppBundle.rawValue))")
            throw FileError.failedToResolveAppBundle
        }
        
        guard let templateFolder = PersistenceManager.templateFolder() else {
            customLog.log(level: .fault,
                          "\(FileError.failedToFindTemplateDirectory.rawValue))")
            throw FileError.failedToFindTemplateDirectory
        }
        
        do {
            try PersistenceManager.duplicateTemplateFiles(from: originFolder, to: templateFolder)
        } catch {
            customLog.log(level: .fault,
                          "\(FileError.failedToImportTemplates.rawValue))")
            throw FileError.failedToImportTemplates
        }
        
        return templateFolder
    }
    
    /// Calculer la date de dernière modification d'un dossier utilisateur `withID` comme étant celle
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
    static func saveToCsvPath(to folder       : Folder,
                              fileName        : String,
                              simulationTitle : String,
                              csvString       : String) throws {
        #if DEBUG
//        print(csvString)
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
        
        /// sauvegarder le fichier dans le fichier: data/Containers/Data/Application/xxx/Documents/Dossier en cours/simulationTitle/csv/fileName
        do {
            // créer le fichier .csv dans le directory 'Documents/Dossier en cours/simulationTitle/csv/' de l'utilisateur
            let csvFile = try folder.createFileIfNeeded(at: AppSettings.shared.csvPath(simulationTitle) + fileName)
            // y écrire le tableau au format csv
            try csvFile.write(csvString, encoding: .utf8)
            #if DEBUG
            customLog.log(level: .info,
                          "Saving \(fileName, privacy: .public) to: \(folder.path + AppSettings.shared.csvPath(simulationTitle) + fileName, privacy: .public)")
            #endif

        } catch let error as NSError {
            // la création à échouée
            customLog.log(level: .fault,
                          "Fault saving \(fileName, privacy: .public) to: \(AppSettings.shared.csvPath(simulationTitle) + fileName, privacy: .public)")
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
    
    static func saveToImagePath(to folder       : Folder,
                                fileName        : String,
                                simulationTitle : String,
                                image           : NSUIImage) throws {
        /// sauvegarder le fichier dans le fichier: data/Containers/Data/Application/xxx/Documents/Dossier en cours/simulationTitle/iamge/fileName
        do {
            // créer le fichier .csv dans le directory 'Documents/Dossier en cours/simulationTitle/csv/' de l'utilisateur
            let imageFile = try folder.createFileIfNeeded(at: AppSettings.shared.imagePath(simulationTitle) + fileName)
            // y écrire le tableau au format csv
            try imageFile.write(image)
            #if DEBUG
            customLog.log(level: .info,
                          "Saving \(fileName, privacy: .public) to: \(folder.path + AppSettings.shared.imagePath(simulationTitle) + fileName, privacy: .public)")
            #endif
//            try Disk.save(image, to: .documents, as: AppSettings.shared.imagePath(simulationTitle) + fileName)
//            // impression debug
//            #if DEBUG
//            Swift.print("saving image to file: ", AppSettings.shared.imagePath(simulationTitle) + fileName)
//            #endif
        } catch let error as NSError {
            // la création à échouée
            customLog.log(level: .fault,
                          "Fault saving \(fileName, privacy: .public) to: \(AppSettings.shared.imagePath(simulationTitle) + fileName, privacy: .public)")
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
