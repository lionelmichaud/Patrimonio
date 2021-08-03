//
//  Unemployment.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Persistable
import AppFoundation
import FileAndFolder

// MARK: - Modèle d'indemnité de licenciement et de Chomage

public struct Unemployment: PersistableModelP {
      
    // MARK: - Nested types

    public enum Cause: String, PickableEnumP, Codable {
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
    
    public struct Model: JsonCodableToFolderP, JsonCodableToBundleP, InitializableP {
        public var indemniteLicenciement : LayoffCompensation
        public var allocationChomage     : UnemploymentCompensation

        public func initialized() -> Unemployment.Model {
            return self
        }
    }
    
    // MARK: - Static Properties

    public static var defaultFileName: String = "UnemploymentModelConfig.json"

    // MARK: - Static Methods

    /// Indique si une personne à droit à une allocation et une indemnité
    /// - Parameter cause: cause de la cessation d'activité
    /// - Returns: vrai si a droit
    public static func canReceiveAllocation(for cause: Cause) -> Bool {
        cause != .demission
    }

    // MARK: - Properties
    
    public var model         : Model?
    public var persistenceSM : PersistenceStateMachine
    
    // MARK: - Initializer
    
    /// Initialize seulement la StateMachine.
    /// L'objet ainsi obtenu n'est pas utilisable en l'état car le modèle n'est pas initialiser.
    /// Pour pouvoir obtenir un objet utilisable il faut utiliser initialiser le model.
    public init() {
        self.persistenceSM = PersistenceStateMachine()
    }
}
