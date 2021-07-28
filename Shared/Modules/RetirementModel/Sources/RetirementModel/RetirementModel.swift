//
//  Retirement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Persistable
import AppFoundation
import Statistics
import FileAndFolder

// https://www.service-public.fr/particuliers/vosdroits/F21552

// MARK: - Modèle de pension de retraite

public struct Retirement: PersistableModel {
    
    // MARK: - Nested types
    
    public struct Model: JsonCodableToFolderP, JsonCodableToBundleP, Initializable {
        public static var defaultFileName : String = "RetirementModelConfig.json"
        public var regimeGeneral: RegimeGeneral
        public var regimeAgirc  : RegimeAgirc
        public var reversion    : PensionReversion
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public func initialized() -> Model {
            self.regimeAgirc.setRegimeGeneral(self.regimeGeneral)
            return self
        }
    }
    
    // MARK: - Static Properties
    
    public static var defaultFileName: String = "RetirementModelConfig.json"
    
    // MARK: - Static methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    public static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        // injecter l'inflation dans les Types d'investissements procurant
        // un rendement non réévalué de l'inflation chaque année
        RegimeGeneral.setSimulationMode(to: simulationMode)
        RegimeAgirc.setSimulationMode(to: simulationMode)
    }
        
    // MARK: - Properties
    
    public var model         : Model?
    public var persistenceSM : PersistenceStateMachine

    public var ageMinimumLegal: Int {
        get {
            model!.regimeGeneral.ageMinimumLegal
        }
        set {
            model?.regimeGeneral.ageMinimumLegal = newValue
            // mémoriser la modification
            persistenceSM.process(event: .modify)
        }
    }

    public var valeurDuPointAGIRC: Double {
        get {
            model!.regimeAgirc.valeurDuPoint
        }
        set {
            model?.regimeAgirc.valeurDuPoint = newValue
            // mémoriser la modification
            persistenceSM.process(event: .modify)
        }
    }

    public var ageMinimumAGIRC: Int {
        get {
            model!.regimeAgirc.ageMinimum
        }
        set {
            model?.regimeAgirc.ageMinimum = newValue
            // mémoriser la modification
            persistenceSM.process(event: .modify)
        }
    }

    // MARK: - Initializers
    
    /// Initialize seulement la StateMachine.
    /// L'objet ainsi obtenu n'est pas utilisable en l'état car le modèle n'est pas initialiser.
    /// Pour pouvoir obtenir un objet utilisable il faut utiliser initialiser le model.
    public init() {
        self.persistenceSM = PersistenceStateMachine()
    }
}
