//
//  Retirement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Statistics

// https://www.service-public.fr/particuliers/vosdroits/F21552

// MARK: - SINGLETON: Modèle de pension de retraite

public struct Retirement {
    
    // MARK: - Nested types
    
    public struct Model: JsonCodableToBundleP {
        public static var defaultFileName : String = "RetirementModelConfig.json"
        public var regimeGeneral: RegimeGeneral
        public var regimeAgirc  : RegimeAgirc
        public var reversion    : PensionReversion
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        func initialized() -> Model {
            var model = self
            model.regimeAgirc.setRegimeGeneral(regimeGeneral)
            return model
        }
    }
    
    // MARK: - Static methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    public static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        // injecter l'inflation dans les Types d'investissements procurant
        // un rendement non réévalué de l'inflation chaque année
        RegimeGeneral.setSimulationMode(to: simulationMode)
        RegimeAgirc.setSimulationMode(to: simulationMode)
    }
    
    // MARK: - Static properties
    
    public static var model: Model = Model(fromFile: Model.defaultFileName).initialized()
    
    // MARK: - Initializer
    
    private init() { }
}
