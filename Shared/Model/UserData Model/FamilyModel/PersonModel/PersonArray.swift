//
//  person2.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 01/06/2021.
//

import Foundation
import Files
import NamedValue
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git

typealias PersistableArrayOfPerson = PersistableArray<Person>
extension PersistableArrayOfPerson {
    /// Initialiser à partir d'un fichier JSON portant le nom `FileNameCst.kFamilyMembersFileName`
    /// contenu dans le dossier `from` du répertoire `Documents`
    /// - Parameter from: dossier où se trouve le fichier JSON à utiliser
    init(from folder : Folder) throws {
        
        self.init()
        
        #if DEBUG
        Swift.print("loading members (Person) from file: ", FileNameCst.kFamilyMembersFileName)
        #endif
        let fileName = FileNameCst.kFamilyMembersFileName
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

        // exécuter la transition
        persistenceSM.process(event: .load)
    }
    
    /// Enregistrer au format JSON dans un fichier portant le nom  `FileNameCst.kFamilyMembersFileName`
    /// dans le folder nommé `to` du répertoire `Documents`
    /// - Parameters:
    ///   - to: nom du dossier du répertoire `Documents`
    public func saveAsJSON(to folder: Folder) throws {
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
        persistenceSM.process(event: .save)
    }
}
