//
//  Extension+Folder-Codable.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 26/05/2021.
//

import Foundation
import Files

public extension Folder {
    /// Lire l'objet de type 'type' au format JSON dans un fichier nommé 'file'
    /// dans le folder 'self'
    /// - Parameters:
    ///   - type: type de l'objet à lire
    ///   - fileName: nom du fichier
    func loadFromJSON <T: Decodable> (_ type: T.Type,
                                      from fileName: String,
                                      dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                      keyDecodingStrategy : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) throws -> T {
        let jsonFile = try self.file(named: fileName)
        return jsonFile.loadFromJSON(type,
                                     dateDecodingStrategy: dateDecodingStrategy,
                                     keyDecodingStrategy: keyDecodingStrategy)
    }
    
    /// Enregistrer l'objet 'object' au format JSON dans un fichier nommé 'file'
    /// dans le folder 'self'
    /// - Parameters:
    ///   - object: objet à enregistrer
    ///   - file: nom du fichier
    func saveAsJSON <T: Encodable> (_ object: T,
                                    to fileName: String,
                                    dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                                    keyEncodingStrategy : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) throws {
        let jsonFile = try self.createFileIfNeeded(withName: fileName)
        jsonFile.saveAsJSON(object,
                            dateEncodingStrategy: dateEncodingStrategy,
                            keyEncodingStrategy: keyEncodingStrategy)
    }
}