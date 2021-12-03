//
//  Sociology.swift
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

// MARK: - DI: Protocols

public protocol PensionDevaluationRateProviderP {
    func pensionDevaluationRate(withMode simulationMode: SimulationModeEnum) -> Double
}

public protocol NbTrimTauxPleinProviderP {
    func nbTrimTauxPlein(withMode simulationMode: SimulationModeEnum) -> Double
}

public protocol ExpensesUnderEvaluationRateProviderP {
    func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double
}

public typealias SocioEconomyModelProviderP =
    PensionDevaluationRateProviderP &
    NbTrimTauxPleinProviderP &
    ExpensesUnderEvaluationRateProviderP

// MARK: - SocioEconomic Model

public struct SocioEconomy: PersistableModelP {
    
    // MARK: - Nested Types
    
    public enum RandomVariable: String, PickableEnumP {
        case pensionDevaluationRate      = "Dévaluation de Pension"
        case nbTrimTauxPlein             = "Trimestres Supplémentaires"
        case expensesUnderEvaluationRate = "Sous-etimation dépenses"
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    public final class Model: JsonCodableToFolderP, JsonCodableToBundleP, InitializableP, SocioEconomyModelProviderP {

        // MARK: - Properties
        
        public var pensionDevaluationRate     : ModelRandomizer<BetaRandomGenerator>
        public var nbTrimTauxPlein            : ModelRandomizer<DiscreteRandomGenerator>
        public var expensesUnderEvaluationRate: ModelRandomizer<BetaRandomGenerator>
        
        // MARK: - Iitializers
        
        /// Créer un clone
        /// - Parameter original: l'original à cloner
        public init?(from original: SocioEconomy.Model?) {
            guard let original = original else {
                return nil
            }
            self.pensionDevaluationRate      = original.pensionDevaluationRate
            self.nbTrimTauxPlein             = original.nbTrimTauxPlein
            self.expensesUnderEvaluationRate = original.expensesUnderEvaluationRate
        }
        
        // MARK: - Methods
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public final func initialized() -> Self {
            self.pensionDevaluationRate.rndGenerator.initialize()
            self.nbTrimTauxPlein.rndGenerator.initialize()
            self.expensesUnderEvaluationRate.rndGenerator.initialize()
            return self
        }
        
        /// Vide l'historique des tirages de chaque variable aléatoire du modèle
        public final func resetRandomHistory() {
            pensionDevaluationRate.resetRandomHistory()
            nbTrimTauxPlein.resetRandomHistory()
            expensesUnderEvaluationRate.resetRandomHistory()
        }
        
        public final func currentRandomizersValues(withMode: SimulationModeEnum) -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.pensionDevaluationRate]      = pensionDevaluationRate.value(withMode: withMode)
            dicoOfRandomVariable[.nbTrimTauxPlein]             = nbTrimTauxPlein.value(withMode: withMode)
            dicoOfRandomVariable[.expensesUnderEvaluationRate] = expensesUnderEvaluationRate.value(withMode: withMode)
            return dicoOfRandomVariable
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        final func randomHistories() -> [RandomVariable: [Double]?] {
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
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        @discardableResult
        public final func nextRun() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.pensionDevaluationRate]      = pensionDevaluationRate.next()
            dicoOfRandomVariable[.nbTrimTauxPlein]             = nbTrimTauxPlein.next()
            dicoOfRandomVariable[.expensesUnderEvaluationRate] = expensesUnderEvaluationRate.next()
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléaoitre avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        public final func setRandomValue(to values: DictionaryOfRandomVariable) {
            pensionDevaluationRate.setRandomValue(to: values[.pensionDevaluationRate]!)
            nbTrimTauxPlein.setRandomValue(to: values[.nbTrimTauxPlein]!)
            expensesUnderEvaluationRate.setRandomValue(to: values[.expensesUnderEvaluationRate]!)
        }
        
        public final func pensionDevaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            pensionDevaluationRate.value(withMode: simulationMode)
        }
        
        public final func nbTrimTauxPlein(withMode simulationMode: SimulationModeEnum) -> Double {
            nbTrimTauxPlein.value(withMode: simulationMode)
        }
        
        public final func expensesUnderEvaluationRate(withMode simulationMode: SimulationModeEnum) -> Double {
            expensesUnderEvaluationRate.value(withMode: simulationMode)
        }
    }
    
    // MARK: - Static Properties
    
    public static var defaultFileName: String = "SocioEconomyModelConfig.json"
    
    // MARK: - Properties
    
    public var model         : Model?
    public var persistenceSM : PersistenceStateMachine
    
    public var pensionDevaluationRateDeterministic: Double {
        get { model!.pensionDevaluationRate.defaultValue }
        set {
            model?.pensionDevaluationRate.defaultValue = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    public var nbTrimTauxPleinDeterministic: Int {
        get { Int(model!.nbTrimTauxPlein.defaultValue.rounded()) }
        set {
            model?.nbTrimTauxPlein.defaultValue = newValue.double()
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    public var expensesUnderEvaluationRateDeterministic: Double {
        get { model!.expensesUnderEvaluationRate.defaultValue }
        set {
            model?.expensesUnderEvaluationRate.defaultValue = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    // MARK: - Initializer
    
    public init() {
        self.persistenceSM = PersistenceStateMachine()
    }
    
    /// Créer un clone
    /// - Parameter original: l'original à cloner
    public init(from original: SocioEconomy) {
        var clone = original
        clone.model = SocioEconomy.Model(from: original.model)
        self = clone
    }
}
