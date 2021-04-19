//
//  Unemployment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - SINGLETON: Modèle d'indemnité de licenciement et de Chomage
public struct Unemployment {
    
    // MARK: - Nested types

    public enum Cause: String, PickableEnum, Codable {
        case demission                          = "Démission"
        case licenciement                       = "Licenciement"
        case ruptureConventionnelleIndividuelle = "Rupture individuelle"
        case ruptureConventionnelleCollective   = "Rupture collective"
        case planSauvegardeEmploi               = "PSE"
        
        // methods
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public struct Model: BundleCodable {
        public static var defaultFileName : String = "UnemploymentModelConfig.json"
        public var indemniteLicenciement  : LayoffCompensation
        public var allocationChomage      : UnemploymentCompensation
    }
    
    // MARK: - Static Properties

    public static var model: Model = Model()
    
    // MARK: - Static Methods

    /// Indique si la personne à droit à une allocation et une indemnité
    /// - Parameter cause: cause de la cessation d'activité
    /// - Returns: vrai si a droit
    public static func canReceiveAllocation(for cause: Cause) -> Bool {
        cause != .demission
    }

    // MARK: - Initializer
    
    private init() {
    }
}
