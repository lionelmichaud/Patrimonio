//
//  FolderJsonCodable.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/05/2021.
//

import Foundation
import Files

// MARK: - Protocol apportant Encodable JSON à partir d'un fichier d'un sous-Directory de 'Documents'

public protocol JsonDecodableFromFolderP: Decodable {
    
    /// Lire les `Data` dans un fichier nommé `fromFile`
    /// dans le folder `fromFolder` du répertoire `Documents`
    /// - Parameters:
    ///   - fromFile: nom du fichier
    ///   - fromFolder: folder du répertoire `Documents`
    func load(fromFile fileName : String,
              fromFolder folder : Folder) throws -> Data

    /// Lit l'objet dans un fichier au format JSON dans un fichier nommé `fromFile`
    /// dans le folder `fromFolder` du répertoire `Documents`
    /// - Parameters:
    ///   - fromFile: nom du fichier
    ///   - fromFolder: folder du répertoire `Documents`
    init(fromFile fileName    : String,
         fromFolder folder    : Folder,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy) throws
}
// implémentation par défaut
public extension JsonDecodableFromFolderP {
    func load(fromFile fileName : String,
              fromFolder folder : Folder) throws -> Data {
        return try folder.load(from: fileName)
    }

    init(fromFile fileName    : String,
         fromFolder folder    : Folder,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy = .iso8601,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) throws {
        self = try folder.loadFromJSON(Self.self,
                                       from                 : fileName,
                                       dateDecodingStrategy : dateDecodingStrategy,
                                       keyDecodingStrategy  : keyDecodingStrategy)
    }
}

// MARK: - Protocol apportant Decodable JSON à partir d'un fichier d'un sous-Directory de 'Documents'

public protocol JsonEncodableToFolderP: Encodable {
        
    /// Enregistrer  `encodeData` dans un fichier nommé `toFile`
    /// dans le folder nommé `toFolder` du répertoire `Documents`
    /// - Parameters:
    ///   - encodeData: data à enregistrer
    ///   - toFile: nom du fichier
    ///   - toFolder: folder du répertoire `Documents`
    func save(_ encodeData    : Data,
              toFile fileName : String,
              toFolder folder : Folder) throws

    /// Enregistrer l'objet `object` au format JSON dans un fichier nommé `toFile`
    /// dans le folder nommé `toFolder` du répertoire `Documents`
    /// - Parameters:
    ///   - toFile: nom du fichier
    ///   - toFolder: folder du répertoire `Documents`
    func saveAsJSON(toFile fileName      : String,
                    toFolder folder      : Folder,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) throws
}
// implémentation par défaut
public extension JsonEncodableToFolderP {
    func save(_ encodeData    : Data,
              toFile fileName : String,
              toFolder folder : Folder) throws {
        try folder.save(encodeData, to: fileName)
    }
    
    func saveAsJSON(toFile fileName      : String,
                    toFolder folder      : Folder,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) throws {
        try folder.saveAsJSON(self,
                              to                   : fileName,
                              dateEncodingStrategy : dateEncodingStrategy,
                              keyEncodingStrategy  : keyEncodingStrategy)
    }
}

// MARK: - Protocol apportant Codable JSON à partir d'un fichier d'un sous-Directory de 'Documents'

public typealias JsonCodableToFolderP = JsonEncodableToFolderP & JsonDecodableFromFolderP
