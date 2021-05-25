//
//  BundleCodable.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol apportant Decodable JSON à partir d'un fichier d'un Bundle de l'application

public protocol BundleDecodable: Decodable {
    
    static var defaultFileName : String { get set }
    
    /// Lit le modèle dans un fichier JSON du Bundle Main
    init(fromFile file        : String?,
         fromBundle bundle    : Bundle,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy)
}

// implémentation par défaut
public extension BundleDecodable {
    init(fromFile file        : String?                          = nil,
         fromBundle bundle    : Bundle                           = Bundle.main,
         dateDecodingStrategy : JSONDecoder.DateDecodingStrategy = .iso8601,
         keyDecodingStrategy  : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) {
        self = bundle.loadFromJSON(Self.self,
                                   from                 : file ?? Self.defaultFileName,
                                   dateDecodingStrategy : dateDecodingStrategy,
                                   keyDecodingStrategy  : keyDecodingStrategy)
    }
}

// MARK: - Protocol apportant Encodable JSON à partir d'un fichier d'un Bundle de l'application

public protocol BundleEncodable: Encodable {
    
    static var defaultFileName : String { get set }
    
    /// Encode l'objet dans un fichier stocké dans le Bundle Main de l'Application
    func saveToBundle(toFile file          : String?,
                      toBundle bundle      : Bundle,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy)
}

// implémentation par défaut
public extension BundleEncodable {
    func saveToBundle(toFile file          : String?                          = nil,
                      toBundle bundle      : Bundle                           = Bundle.main,
                      dateEncodingStrategy : JSONEncoder.DateEncodingStrategy = .iso8601,
                      keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) {
        bundle.saveAsJSON(self,
                          to                   : file ?? Self.defaultFileName,
                          dateEncodingStrategy : dateEncodingStrategy,
                          keyEncodingStrategy  : keyEncodingStrategy)
    }
}

// MARK: - Protocol apportant Codable JSON à partir d'un fichier d'un Bundle de l'application

public typealias BundleCodable = BundleEncodable & BundleDecodable
