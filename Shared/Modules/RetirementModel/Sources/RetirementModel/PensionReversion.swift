//
//  PensionReversion.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

public struct PensionReversion: Codable {
    
    // MARK: - Nested types
    
    // https://www.retraite.com/dossier-retraite/pension-de-reversion/evolution-de-la-pension-de-reversion-dans-la-reforme-des-retraites.html
    public struct Model: JsonCodableToBundleP, Versionable {
        public var version: Version
        let tauxReversion: Double // [0, 100] // 70% de la somme des deux pensions
    }
    
    // MARK: - Properties
    
    public var model: Model
    
    // MARK: - Initializer
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: - Methods
    
    public func pensionReversion(pensionDecedent : Double,
                                 pensionSpouse   : Double) -> Double {
        (pensionDecedent + pensionSpouse) * model.tauxReversion / 100.0
    }
    /// Encode l'objet dans un fichier stocké dans le Bundle
    func saveAsJSON(toFile file          : String,
                    toBundle bundle      : Bundle,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        model.saveAsJSON(toFile               : file,
                         toBundle             : bundle,
                         dateEncodingStrategy : dateEncodingStrategy,
                         keyEncodingStrategy  :  keyEncodingStrategy)
    }
}
