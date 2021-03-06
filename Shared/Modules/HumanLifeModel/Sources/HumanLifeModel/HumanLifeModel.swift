//
//  HumanLifeModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Statistics

// MARK: - SINGLETON: Human Life Model

public struct HumanLife {
    
    // MARK: - Nested Types
    
    enum RandomVariable: String, PickableEnum {
        case menLifeExpectation    = "Espérance de Vie d'un Homme"
        case womenLifeExpectation  = "Espérance de Vie d'uns Femme"
        case nbOfYearsOfdependency = "Nombre d'années de Dépendance"
        
        var pickerString: String {
            return self.rawValue
        }
    }
    
    public struct Model: BundleCodable {
        public static var defaultFileName : String = "HumanLifeModelConfig.json"
        public var menLifeExpectation    : ModelRandomizer<DiscreteRandomGenerator>
        public var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
        public var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
        public let minAgeUniversity      : Int
        public let minAgeIndependance    : Int

        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        func initialized() -> Model {
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
    
    public static var model: Model = Model().initialized()

    // MARK: - Initializer
    
    private init() {
    }
}
