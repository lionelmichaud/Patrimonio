//
//  Sociology.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Statistics

// MARK: - DI: Protocol InflationProviderProtocol

public protocol PensionDevaluationRateProviderProtocol {
    func pensionDevaluationRate(withMode simulationMode: SimulationModeEnum) -> Double
}

public protocol NbTrimTauxPleinProviderProtocol {
    func nbTrimTauxPlein(withMode simulationMode: SimulationModeEnum) -> Double
}

public protocol ExpensesUnderEvaluationRateProviderProtocol {
    func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double
}

public typealias SocioEconomyModelProvider = PensionDevaluationRateProviderProtocol &
    NbTrimTauxPleinProviderProtocol &
    ExpensesUnderEvaluationRateProviderProtocol

// MARK: - SINGLETON: SocioEconomic Model

public struct SocioEconomy {
    
    // MARK: - Nested Types
    
    public enum RandomVariable: String, PickableEnum {
        case pensionDevaluationRate      = "Dévaluation de Pension"
        case nbTrimTauxPlein             = "Trimestres Supplémentaires"
        case expensesUnderEvaluationRate = "Sous-etimation dépenses"

        public var pickerString: String {
            return self.rawValue
        }
    }
    
    typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    public struct Model: BundleCodable, SocioEconomyModelProvider {
        public static var defaultFileName : String = "SocioEconomyModelConfig.json"
        var pensionDevaluationRate     : ModelRandomizer<BetaRandomGenerator>
        var nbTrimTauxPlein            : ModelRandomizer<DiscreteRandomGenerator>
        public var expensesUnderEvaluationRate: ModelRandomizer<BetaRandomGenerator>
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public func initialized() -> Model {
            var model = self
            model.pensionDevaluationRate.rndGenerator.initialize()
            model.nbTrimTauxPlein.rndGenerator.initialize()
            model.expensesUnderEvaluationRate.rndGenerator.initialize()
            return model
        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        mutating func resetRandomHistory() {
            pensionDevaluationRate.resetRandomHistory()
            nbTrimTauxPlein.resetRandomHistory()
            expensesUnderEvaluationRate.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.pensionDevaluationRate]      = pensionDevaluationRate.next()
            dicoOfRandomVariable[.nbTrimTauxPlein]             = nbTrimTauxPlein.next()
            dicoOfRandomVariable[.expensesUnderEvaluationRate] = expensesUnderEvaluationRate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléaoitre avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            pensionDevaluationRate.setRandomValue(to: values[.pensionDevaluationRate]!)
            nbTrimTauxPlein.setRandomValue(to: values[.nbTrimTauxPlein]!)
            expensesUnderEvaluationRate.setRandomValue(to: values[.expensesUnderEvaluationRate]!)
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .pensionDevaluationRate:
                        dico[randomVariable] = pensionDevaluationRate.randomHistory
                    case .nbTrimTauxPlein:
                        dico[randomVariable] = nbTrimTauxPlein.randomHistory
                    case .expensesUnderEvaluationRate:
                        dico[randomVariable] = expensesUnderEvaluationRate.randomHistory
                }
            }
            return dico
        }

        public func pensionDevaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            pensionDevaluationRate.value(withMode: simulationMode)
        }

        public func nbTrimTauxPlein(withMode simulationMode: SimulationModeEnum) -> Double {
            nbTrimTauxPlein.value(withMode: simulationMode)
        }

        public func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            expensesUnderEvaluationRate.value(withMode: simulationMode)
        }
    }

    // MARK: - Static Properties

    public static var model: Model = Model().initialized()

    // MARK: - Initializer
    
    private init() {
    }
}
