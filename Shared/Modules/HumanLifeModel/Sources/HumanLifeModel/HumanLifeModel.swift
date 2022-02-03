//
//  HumanLifeModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Persistable
import AppFoundation
import Statistics
import FileAndFolder

// MARK: - Human Life Model

public struct HumanLife: PersistableModelP {
    
    // MARK: - Nested Types
    
    public enum RandomVariable: String, PickableEnumP {
        case menLifeExpectation    = "Espérance de Vie d'un Homme"
        case womenLifeExpectation  = "Espérance de Vie d'uns Femme"
        case nbOfYearsOfdependency = "Nombre d'années de Dépendance"
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public struct Model: JsonCodableToFolderP, JsonCodableToBundleP, InitializableP {
        public var menLifeExpectation    : ModelRandomizer<DiscreteRandomGenerator>
        public var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
        public var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
        public let minAgeUniversity      : Int
        public let minAgeIndependance    : Int
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public func initialized() -> Self {
            var model = self
            model.menLifeExpectation.rndGenerator.initialize()
            model.womenLifeExpectation.rndGenerator.initialize()
            model.nbOfYearsOfdependency.rndGenerator.initialize()
            return model
        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        public mutating func resetRandomHistory() {
            menLifeExpectation.resetRandomHistory()
            womenLifeExpectation.resetRandomHistory()
            nbOfYearsOfdependency.resetRandomHistory()
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        /// - Returns: dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .menLifeExpectation:
                        dico[randomVariable] = menLifeExpectation.randomHistory
                    case .womenLifeExpectation:
                        dico[randomVariable] = womenLifeExpectation.randomHistory
                    case .nbOfYearsOfdependency:
                        dico[randomVariable] = nbOfYearsOfdependency.randomHistory
                }
            }
            return dico
        }
    }
    
    // MARK: - Static Properties
    
    public static var defaultFileName: String = "HumanLifeModelConfig.json"
    
    // MARK: - Properties
    
    public var model         : Model?
    public var persistenceSM : PersistenceStateMachine
    
//    public var menLifeExpectationDeterministic: Int {
//        get { Int(model!.menLifeExpectation.defaultValue.rounded()) }
//        set {
//            model?.menLifeExpectation.defaultValue = newValue.double()
//            // mémoriser la modification
//            persistenceSM.process(event: .onModify)
//        }
//    }
//    public var womenLifeExpectationDeterministic: Int {
//        get { Int(model!.womenLifeExpectation.defaultValue.rounded()) }
//        set {
//            model?.womenLifeExpectation.defaultValue = newValue.double()
//            // mémoriser la modification
//            persistenceSM.process(event: .onModify)
//        }
//    }
//    public var nbOfYearsOfdependencyDeterministic: Int {
//        get { Int(model!.nbOfYearsOfdependency.defaultValue.rounded()) }
//        set {
//            model?.nbOfYearsOfdependency.defaultValue = newValue.double()
//            // mémoriser la modification
//            persistenceSM.process(event: .onModify)
//        }
//    }

    // MARK: - Initializers

    /// Initialize seulement la StateMachine.
    /// L'objet ainsi obtenu n'est pas utilisable en l'état car le modèle n'est pas initialiser.
    /// Pour pouvoir obtenir un objet utilisable il faut utiliser un des autres init().
    /// Cet init() n'est utile que pour pouvoir créer un StateObject dans App.main()
    public init() {
        self.persistenceSM = PersistenceStateMachine()
    }
}
