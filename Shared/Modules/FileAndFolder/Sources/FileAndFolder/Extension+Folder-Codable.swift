//
//  Extension+Folder-Codable.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 26/05/2021.
//

import Foundation
import os
import Files

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Folder.extension")

public extension Folder {
    /// Lire les `Data` dans un fichier nommé `fileName`
    /// dans le folder `self`
    /// - Parameters:
    ///   - fileName: nom du fichier
    func load(from fileName: String) throws -> Data {
        do {
            let file = try self.file(named: fileName)
            return try file.read()
        } catch {
            let errorStr = String(describing: (error as! LocationError))
            customLog.log(level: .error, "\(errorStr)")
            throw error
        }
    }
    /// Lire l'objet de type `type` au format JSON dans un fichier nommé `fileName`
    /// dans le folder `self`
    /// - Parameters:
    ///   - type: type de l'objet à lire
    ///   - fileName: nom du fichier
    func loadFromJSON <T: Decodable> (_ type: T.Type,
                                      from fileName: String,
                                      dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                      keyDecodingStrategy : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) throws -> T {
        do {
            let jsonFile = try self.file(named: fileName)
            return jsonFile.loadFromJSON(type,
                                         dateDecodingStrategy: dateDecodingStrategy,
                                         keyDecodingStrategy: keyDecodingStrategy)
        } catch {
            let errorStr = String(describing: (error as! LocationError))
            customLog.log(level: .error, "\(errorStr)")
            throw error
        }
    }
    
    /// Enregistrer  `encodeData` dans un fichier nommé `fileName`
    /// dans le folder `self`
    /// - Parameters:
    ///   - encodeData: data à enregistrer
    ///   - fileName: nom du fichier
    func save(_ encodeData: Data,
              to fileName: String) throws {
        do {
            let file = try self.createFileIfNeeded(withName: fileName)
            file.save(encodeData)
        } catch {
            let errorStr = String(describing: (error as! LocationError))
            customLog.log(level: .error, "\(errorStr)")
            throw error
        }
    }
    
    /// Enregistrer l'objet `object` au format JSON dans un fichier nommé `fileName`
    /// dans le folder `self`
    /// - Parameters:
    ///   - object: objet à enregistrer
    ///   - fileName: nom du fichier
    func saveAsJSON <T: Encodable> (_ object: T,
                                    to fileName: String,
                                    dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                                    keyEncodingStrategy : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) throws {
        do {
            let jsonFile = try self.createFileIfNeeded(withName: fileName)
            jsonFile.saveAsJSON(object,
                                dateEncodingStrategy: dateEncodingStrategy,
                                keyEncodingStrategy: keyEncodingStrategy)
        } catch {
            let errorStr = String(describing: (error as! LocationError))
            customLog.log(level: .error, "\(errorStr)")
            throw error
        }
    }
}
