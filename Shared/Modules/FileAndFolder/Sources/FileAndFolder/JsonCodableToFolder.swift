//
//  FolderJsonCodable.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/05/2021.
//

import Foundation
import Files

// MARK: - Protocol apportant Encodable JSON à partir d'un fichier d'un sous-Directory de 'Documents'

public protocol JsonDecodableToFolderP: Decodable {
    
    static var defaultFileName : String { get set }
    
    /// Lit le modèle dans un fichier JSON du Bundle
    init(fromFile file        : String,
         fromFolder folder    : Folder,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy) throws
}
// implémentation par défaut
public extension JsonDecodableToFolderP {
    init(fromFile file        : String                           = defaultFileName,
         fromFolder folder    : Folder,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy = .iso8601,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) throws {
        self = try folder.loadFromJSON(Self.self,
                                       from                 : file,
                                       dateDecodingStrategy : dateDecodingStrategy,
                                       keyDecodingStrategy  : keyDecodingStrategy)
    }
}

// MARK: - Protocol apportant Decodable JSON à partir d'un fichier d'un sous-Directory de 'Documents'

public protocol JsonEncodableToFolderP: Encodable {
    
    static var defaultFileName : String { get set }
    
    /// Encode l'objet dans un fichier stocké dans le Bundle Main de l'Application
    func saveAsJSON(toFile file          : String,
                    toFolder folder      : Folder,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) throws
}
// implémentation par défaut
public extension JsonEncodableToFolderP {
    func saveAsJSON(toFile file          : String                           = defaultFileName,
                    toFolder folder      : Folder,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) throws {
        try folder.saveAsJSON(self,
                              to                   : file,
                              dateEncodingStrategy : dateEncodingStrategy,
                              keyEncodingStrategy  : keyEncodingStrategy)
    }
}

// MARK: - Protocol apportant Codable JSON à partir d'un fichier d'un sous-Directory de 'Documents'

public typealias JsonCodableToFolderP = JsonEncodableToFolderP & JsonDecodableToFolderP
