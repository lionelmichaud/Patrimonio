//
//  Persistence.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 13/05/2021.
//

import Foundation
import UIKit
import os
import AppFoundation
import FileAndFolder
import NamedValue
import Files
//import Charts // https://github.com/danielgindi/Charts.git

private let customLog = Logger(subsystem : "me.michaud.lionel.Patrimonio",
                               category  : "PersistenceManager")

// MARK: - Extension de Folder

public extension Folder {
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

public enum FileError: String, Error {
    case failedToSaveCashFlowCsv           = "La sauvegarde de l'historique des bilans a échoué"
    case failedToSaveBalanceSheetCsv       = "La sauvegarde de l'historique des cash-flow a échoué"
    case failedToSaveMonteCarloCsv         = "La sauvegarde de l'historique des runs a échoué"
    case failedToSaveSuccessionsCSV        = "La sauvegarde des successions légales a échoué"
    case failedToSaveLifeInsSuccessionsCSV = "La sauvegarde des successions assurance vie a échoué"
    case failedToResolveAppBundle          = "Impossible de trouver le répertoire 'App Bundle'"
    case failedToResolveCsvFolder          = "Impossible de trouver le répertoire 'CSV'"
    case failedToResolveDocuments          = "Impossible de trouver le répertoire 'Documents' de l'utilisateur"
    case failedToResolveLibrary            = "Impossible de trouver le répertoire 'Library' de l'utilisateur"
    case failedToFindTemplateDirectory     = "Impossible de trouver le répertoire 'template' dans le répertoire 'Library' de l'utilisateur"
    case failedToCreateTemplateDirectory   = "Impossible de créer le répertoire 'template' dans le répertoire 'Library' de l'utilisateur"
    case directoryToDuplicateDoesNotExist  = "Le répertoire à dupliquer n'est pas défini"
    case failedToDuplicateTemplates        = "Echec de la copie des templates"
    case templatesDossierNotInitialized    = "Dossier 'templates' non initializé"
    case failedToImportTemplates           = "Echec de l'importation des templates depuis Bundle.Main vers 'Library'"
    case failedToCheckCompatibility        = "Impossible de vérifier la compatibilité avec la version de l'application"
}

public struct PersistenceManager {
    
    // MARK: - Static Properties
    
    public static var templateDirIsCompatibleWithAppVersion: Bool = true
    
    // MARK: - Static Methods
    
    /// Itérer une action `perform` sur tous les dossiers `utilisateur` du directory `Documents`
    /// - Parameter perform: action à réaliser sur chaque Folder
    /// - Throws: `FileError.failedToResolveDocuments`
    public static func forEachUserFolder(perform: (Folder) throws -> Void) throws {
        // rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            let error = FileError.failedToResolveDocuments
            customLog.log(level: .error,
                          "\(error.rawValue)")
            throw error
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
        // rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            let error = FileError.failedToResolveDocuments
            customLog.log(level: .error,
                          "\(error.rawValue)")
            throw error
        }
        
        // créer le directory USER pour le nouveau Dossier
        let targetFolder: Folder
        targetFolder = try documentsFolder.createSubfolder(named: id.uuidString)
        
        // récupérer le dossier 'templates'
        guard let originFolder = templateFolder() else {
            let error = FileError.templatesDossierNotInitialized
            customLog.log(level: .error,
                          "\(error.rawValue)")
            throw error
        }
        
        // y dupliquer les fichiers du directory originFolder
        do {
            try duplicateAllJsonFiles(from: originFolder, to: targetFolder)
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
        // rechercher le dossier 'Documents' de l'utilisateur
        guard let documentsFolder = Folder.documents else {
            let error = FileError.failedToResolveDocuments
            customLog.log(level: .error,
                          "\(error.rawValue)")
            throw error
        }
        
        // créer le directory USER pour le nouveau Dossier
        let targetFolder: Folder
        targetFolder = try documentsFolder.createSubfolder(named: id.uuidString)
        
        // récupérer le dossier à dupliquer
        guard let originFolder = originFolder else {
            let error = FileError.directoryToDuplicateDoesNotExist
            customLog.log(level: .error,
                          "\(error.rawValue)")
            throw error
        }
        
        // y dupliquer les fichiers du directory originFolder
        do {
            try duplicateAllJsonFiles(from: originFolder, to: targetFolder)
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
        // rechercher le dossier 'Documents' de l'utilisateur
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
    /// Créer le directorty au besoin et importer les fichiers du Bundle de l'App.
    /// - Returns: Folder pointant sur le directory contenant les templates ou 'nil' si le dossier n'est pas trouvé
    public static func templateFolder() -> Folder? {
        // rechercher le dossier 'Library' de l'utilisateur
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
                    let newTemplateFolder = try importTemplatesFromAppAndCheckCompatibility()
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
    
    /// Retourne le Folder dans lequel sont enregistrés les fichier `CSV`
    /// résultant d'une simulation nommée `forSimulationTitle`
    /// - Parameters:
    ///   - folder: Folder actif dans lequel se trouve le Folder `CSV`
    ///   - forSimulationTitle: nom de la de la simulation
    /// - Returns: Folder dans lequel sont enregistrés les fichier `CSV`résultant d'une simulation
    public static func csvFolder(in folder          : Folder,
                                 forSimulationTitle : String) throws -> Folder {
        return try Folder(path: folder.path + AppSettings.shared.csvPath(forSimulationTitle))
    }
    
    /// Retourne le Folder dans lequel sont enregistrés les fichier `image`
    /// résultant d'une simulation nommée `forSimulationTitle`
    /// - Parameters:
    ///   - folder: Folder actif dans lequel se trouve le Folder `image`
    ///   - forSimulationTitle: nom de la de la simulation
    /// - Returns: Folder dans lequel sont enregistrés les fichier `image`résultant d'une simulation
    public static func imageFolder(in folder          : Folder,
                                   forSimulationTitle : String) throws -> Folder {
        return try Folder(path: folder.path + AppSettings.shared.imagePath(forSimulationTitle))
    }
    
    /// Vérifier la compatibilité de version entre l'App et le directory `targetFolder`
    /// - Note: Les versions sont compatibles si elles portent la même version majeure
    public static func checkCompatibilityWithAppVersion(of targetFolder: Folder) throws -> Bool {
        if let appMajorVersion = AppVersion.shared.version.major {
            do {
                let targetMajorVersion = try targetFolder.loadFromJSON(
                    AppVersion.self,
                    from                 : AppVersion.fileName,
                    dateDecodingStrategy : .iso8601,
                    keyDecodingStrategy  : .useDefaultKeys).version.major
                return (appMajorVersion == targetMajorVersion)
                
            } catch {
                // le chargement du fichier AppVersion.json du dossier s'est mal passé
                if let theError = (error as? LocationError) {
                    // à cause d'un pb de gestion de fichier
                    switch theError.reason {
                        case .missing:
                            // le fichier AppVersion.json en manquant dans le dossier
                            return false
                        default:
                            // à cause d'une autre raison
                            customLog.log(level: .fault,
                                          "\(FileError.failedToCheckCompatibility.rawValue) de '\(AppVersion.fileName)'")
                            throw FileError.failedToCheckCompatibility
                    }
                } else {
                    // à cause d'une autre raison
                    customLog.log(level: .fault,
                                  "\(FileError.failedToCheckCompatibility.rawValue) de '\(AppVersion.fileName)'")
                    throw FileError.failedToCheckCompatibility
                }
            }
            
        } else {
            customLog.log(level: .fault,
                          "\(FileError.failedToCheckCompatibility.rawValue) de '\(AppVersion.fileName)'")
            throw FileError.failedToCheckCompatibility
        }
    }
    
    /// Importer les fichiers template depuis le `Bundle Main` de l'Application
    /// vers le répertoire `Library/template` si'ils n'y sont pas présents.
    /// Vérifier la compatibilité entre la version de l'app et la verison du répertoire `Library/template`.
    /// - Returns: le dossier 'template' si l'import a réussi, 'nil' sinon
    @discardableResult
    public static func importTemplatesFromAppAndCheckCompatibility() throws -> Folder {
        guard let originFolder = Folder.application else {
            let error = FileError.failedToResolveAppBundle
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
        
        guard let templateFolder = templateFolder() else {
            let error = FileError.failedToFindTemplateDirectory
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
        
        do {
            try duplicateAllJsonFiles(from: originFolder, to: templateFolder)
            templateDirIsCompatibleWithAppVersion = try checkCompatibilityWithAppVersion(of: templateFolder)
        } catch {
            let error = FileError.failedToImportTemplates
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
        
        return templateFolder
    }
    
    /// Importer les fichiers template depuis le `Bundle Main` de l'Application
    /// vers le répertoire `Library/template` si'ils n'y sont pas présents.
    public static func forcedImportTemplatesFromApp() throws {
        guard let originFolder = Folder.application else {
            let error = FileError.failedToResolveAppBundle
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
        
        guard let templateFolder = templateFolder() else {
            let error = FileError.failedToFindTemplateDirectory
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
        
        do {
            try duplicateAllJsonFiles(from        : originFolder,
                                      to          : templateFolder,
                                      forceUpdate : true)
        } catch {
            let error = FileError.failedToImportTemplates
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
    }
    
    /// Dupliquer certains fichiers du Bundle Application vers `toFolder`
    /// Dupliquer le fichier "AppVersion.json" du Bundle Appli vers `toFolder`
    /// - Parameters:
    ///   - toFolder: répertoire de destination
    ///   - readWriteFiles: closure de copie des fichiers souhaités
    /// - Throws: FileError.failedToResolveAppBundle
    public static func duplicateFilesFromApp(toFolder       : Folder,
                                             readWriteFiles : (Folder, Folder) throws -> Void) throws {
        guard let fromFolder = Folder.application else {
            let error = FileError.failedToResolveAppBundle
            customLog.log(level: .fault,
                          "\(error.rawValue))")
            throw error
        }
        
        if fromFolder.containsFile(named: AppVersion.fileName) {
            // enregister la version de l'app dans le directory toFolder
            let file = try fromFolder.file(at: AppVersion.fileName)
            try toFolder.saveAsJSON(AppVersion.shared,
                                    to                   : file.name,
                                    dateEncodingStrategy : .iso8601,
                                    keyEncodingStrategy  : .useDefaultKeys)
        }
        
        try readWriteFiles(fromFolder, toFolder)
    }
    
    /// Dupliquer tous les fichiers JSON présents dans le répertoire `originFolder`
    /// vers le répertoire `targetFolder`
    /// - Parameters:
    ///   - originFolder: répertoire source
    ///   - targetFolder: répertoire destination
    ///   - forceUpdate: si false alors ne copie pas les fichiers s'ils sont déjà présents dans le répertoire `targetFolder`
    /// - Throws:`FileError.withContentDuplicatedFrom`
    fileprivate static func duplicateAllJsonFiles(from originFolder : Folder,
                                                  to targetFolder   : Folder,
                                                  forceUpdate: Bool = false) throws {
        do {
            try originFolder.files.forEach { file in
                if let ext = file.extension, ext == "json" {
                    // recopier le fichier s'il n'est pas présent dans le directory targetFolder
                    if !targetFolder.containsFile(named: file.name) || forceUpdate {
                        if file.name == AppVersion.fileName {
                            // enregister la version de l'app dans le directory targetFolder
                            try targetFolder.saveAsJSON(AppVersion.shared,
                                                        to                   : file.name,
                                                        dateEncodingStrategy : .iso8601,
                                                        keyEncodingStrategy  : .useDefaultKeys)
                        } else {
                            do {
                                let targetFile = try targetFolder.file(named: file.name)
                                try targetFile.delete()
                                try file.copy(to: targetFolder)
                            } catch {
                                try file.copy(to: targetFolder)
                            }
                        }
                    }
                }
            }
        } catch {
            customLog.log(level: .fault,
                          "\(FileError.failedToDuplicateTemplates.rawValue) de \(originFolder.name) vers \(targetFolder.name)")
            throw FileError.failedToDuplicateTemplates
        }
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
    public static func saveToCsvPath(to folder       : Folder,
                                     fileName        : String,
                                     simulationTitle : String,
                                     csvString       : String) throws {
//        #if DEBUG
        #if targetEnvironment(simulator)
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
    
    public static func saveToImagePath(to folder       : Folder,
                                       fileName        : String,
                                       simulationTitle : String,
                                       image           : UIImage) throws {
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
