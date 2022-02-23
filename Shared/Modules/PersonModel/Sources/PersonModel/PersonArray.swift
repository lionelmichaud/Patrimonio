//
//  person2.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 01/06/2021.
//

import Foundation
import os
import AppFoundation
import Files
import NamedValue
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git
import ModelEnvironment
import Persistence

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio",
                               category: "Model.PersonModel")

/// Tableau de Person
///
/// Usage:
///
///     members  = try PersistableArrayOfPerson(fromFolder: folder,
///                                                using     : model)
///
///     // mettre à jour les membres de la famille existants avec un nouveau model
///     members.initialize(using: model)
///
public typealias PersistableArrayOfPerson = PersistableArray<Person>
public extension PersistableArrayOfPerson {
    /// Initialiser à partir d'un fichier JSON portant le nom `FileNameCst.kFamilyMembersFileName`
    /// contenu dans le dossier `folder` du répertoire `Documents`
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - model: modèle à utiliser pour initialiser les membres de la famille
    /// - Throws: en cas d'échec de lecture des données
    init(fromFolder folder : Folder,
         using model       : Model) throws {
        
        self.init()
        
        let fileName = FileNameCst.kFamilyMembersFileName
        #if DEBUG
        Swift.print("loading members (Person) from file: ", fileName)
        #endif
        // lire les person dans le fichier JSON du dossier `Folder`
        let data = try self.load(fromFile   : fileName,
                                 fromFolder : folder)
        do {
            items = try Person.coder.decoder
                .decode([Wrap].self, from: data)
                .map { $0.wrapped as! Person }
            
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("Failed to decode \(fileName) in documents directory because it appears to be invalid JSON – \(context.codingPath)–  \(context.debugDescription)")
        } catch {
            fatalError("Failed to decode \(fileName) in documents directory: \(error.localizedDescription)")
        }
        
        // initialiser les propriétés des Personnes qui ne peuvent pas être lues dans le fichier JSON
        initialize(using: model)
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    /// Initialiser à partir d'un fichier JSON portant le nom `FileNameCst.kFamilyMembersFileName`
    /// contenu dans le dossier `bundle`
    /// - Parameters:
    ///   - bundle: le bundle où se trouve le fichier JSON à utiliser
    ///   - model: modèle à utiliser pour initialiser les membres de la famille
    init(fromBundle bundle : Bundle,
         using model       : Model) throws {
        
        self.init()

        let fileName = FileNameCst.kFamilyMembersFileName
        
        // find file's URL
        guard let url = bundle.url(forResource: fileName, withExtension: nil) else {
            customLog.log(level: .fault, "Failed to locate file '\(fileName)' in bundle.")
            fatalError("Failed to locate file '\(fileName)' in bundle.")
        }
        // MARK: - DEBUG - A supprimer
        #if DEBUG
        print("decoding file: ", url)
        #endif
        
        // load data from URL
        guard let data = try? Data(contentsOf: url) else {
            customLog.log(level: .fault, "Failed to load file '\(fileName)' from bundle.")
            fatalError("Failed to load file '\(fileName)' from bundle.")
        }
        
        #if DEBUG
        Swift.print("loading members (Person) from file: ", fileName)
        #endif
        do {
            items = try Person.coder.decoder
                .decode([Wrap].self, from: data)
                .map { $0.wrapped as! Person }
            
        } catch DecodingError.keyNotFound(let key, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            fatalError("Failed to decode \(fileName) in documents directory due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            fatalError("Failed to decode \(fileName) in documents directory because it appears to be invalid JSON – \(context.codingPath)–  \(context.debugDescription)")
        } catch {
            fatalError("Failed to decode \(fileName) in documents directory: \(error.localizedDescription)")
        }
        
        // initialiser les propriétés des Personnes qui ne peuvent pas être lues dans le fichier JSON
        initialize(using: model)

        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
   /// Enregistrer au format JSON dans un fichier portant le nom  `FileNameCst.kFamilyMembersFileName`
    /// dans le folder nommé `folder` du répertoire `Documents`
    /// - Parameters:
    ///   - folder: nom du dossier du répertoire `Documents`
    func saveAsJSON(to folder: Folder) throws {
        // encode to JSON file
        if let encoded: Data = try? Person.coder.encoder.encode(items.map { Wrap(wrapped: $0) }) {
            let fileName = FileNameCst.kFamilyMembersFileName
            #if DEBUG
            Swift.print("saving members (Person) to file: ", FileNameCst.kFamilyMembersFileName)
            #endif
            if let jsonString = String(data: encoded, encoding: .utf8) {
                #if DEBUG
                Swift.print(jsonString)
                #endif
            } else {
                Swift.print("failed to convert 'family.members' encoded data to string.")
            }
            do {
                // sauvegader les données
                try self.save(encoded,
                              toFile   : FileNameCst.kFamilyMembersFileName,
                              toFolder : folder)
            } catch {
                fatalError("Failed to save data to '\(fileName)' in documents directory.")
            }
        } else {
            fatalError("Failed to encode 'family.members' to JSON format.")
        }
        // exécuter la transition
        persistenceSM.process(event: .onSave)
    }
    
    func initialize(using model: Model) {
        self.items.forEach { person in
            // initialiser l'age de décès avec la valeur moyenne déterministe
            // initialiser le nombre d'années de dépendence
            person.initialize(using: model)
        }
    }
}
