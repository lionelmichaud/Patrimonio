//
//  BundleCodable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol apportant Decodable JSON à partir d'un fichier d'un Bundle de l'application

public protocol JsonDecodableToBundle: Decodable {
    
    static var defaultFileName : String { get set }
    
    /// Lit le modèle dans un fichier JSON du Bundle 
    init(fromFile file        : String,
         fromBundle bundle    : Bundle,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy)
}

// implémentation par défaut
public extension JsonDecodableToBundle {
    init(fromFile file        : String                           = defaultFileName,
         fromBundle bundle    : Bundle                           = Bundle.main,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy = .iso8601,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) {
        self = bundle.loadFromJSON(Self.self,
                                   from                 : file,
                                   dateDecodingStrategy : dateDecodingStrategy,
                                   keyDecodingStrategy  : keyDecodingStrategy)
    }
}

// MARK: - Protocol apportant Encodable JSON à partir d'un fichier d'un Bundle de l'application

public protocol JsonEncodableToBundle: Encodable {
    
    static var defaultFileName : String { get set }
    
    /// Encode l'objet dans un fichier stocké dans le Bundle Main de l'Application
    func saveToBundle(toFile file          : String,
                      toBundle bundle      : Bundle,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy)
}

// implémentation par défaut
public extension JsonEncodableToBundle {
    func saveToBundle(toFile file          : String                           = defaultFileName,
                      toBundle bundle      : Bundle                           = Bundle.main,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) {
        bundle.saveAsJSON(self,
                          to                   : file,
                          dateEncodingStrategy : dateEncodingStrategy,
                          keyEncodingStrategy  : keyEncodingStrategy)
    }
}

// MARK: - Protocol apportant Codable JSON à partir d'un fichier d'un Bundle de l'application

public typealias JsonCodableToBundle = JsonEncodableToBundle & JsonDecodableToBundle
