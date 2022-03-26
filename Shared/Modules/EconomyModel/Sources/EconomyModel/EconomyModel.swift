//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import Persistable
import AppFoundation
import Statistics
import FileAndFolder

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Economy")

// MARK: - DI: Protocol InflationProviderProtocol

public protocol InflationProviderP {
    func inflation(withMode simulationMode: SimulationModeEnum) -> Double
}

public protocol FinancialRatesProviderP {
    func rates(in year            : Int,
               withMode mode      : SimulationModeEnum,
               simulateVolatility : Bool)
    -> (securedRate : Double,
        stockRate   : Double)
    
    func rates(withMode mode : SimulationModeEnum)
    -> (securedRate : Double,
        stockRate   : Double)
}

public typealias EconomyModelProviderP = InflationProviderP & FinancialRatesProviderP

// MARK: - Economy Model

public struct Economy: PersistableModelP {
    
    // MARK: - Nested Types
    
    public enum ModelError: Error {
        case outOfBounds
    }
    
    public enum RandomVariable: String, PickableEnumP {
        case inflation   = "Inflation"
        case securedRate = "Rendements Sûrs"
        case stockRate   = "Rendements Actions"
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    // MARK: - Modèles statistiques de générateurs aléatoires
    public struct RandomizersModel: Codable, Equatable {
        
        // MARK: - Properties
        
        public var inflation   : ModelRandomizer<BetaRandomGenerator>
        public var securedRate : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        public var stockRate   : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        public var securedVolatility : Double // % [0, 100]
        public var stockVolatility   : Double // % [0, 100]
        
        // MARK: - Initializers
        
        /// Lit le modèle dans un fichier JSON du Bundle Main
        func initialized() -> RandomizersModel {
            var model = self
            model.inflation.rndGenerator.initialize()
            model.securedRate.rndGenerator.initialize()
            model.stockRate.rndGenerator.initialize()
            return model
        }
        
        // MARK: - Methods
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        fileprivate mutating func resetRandomHistory() {
            inflation.resetRandomHistory()
            securedRate.resetRandomHistory()
            stockRate.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        fileprivate mutating func next() -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable           = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.inflation]   = inflation.next()
            dicoOfRandomVariable[.securedRate] = securedRate.next()
            dicoOfRandomVariable[.stockRate]   = stockRate.next()
            return dicoOfRandomVariable
        }
        
        fileprivate func current(withMode mode : SimulationModeEnum) -> DictionaryOfRandomVariable {
            var dicoOfRandomVariable           = DictionaryOfRandomVariable()
            dicoOfRandomVariable[.inflation]   = inflation.value(withMode: mode)
            dicoOfRandomVariable[.securedRate] = securedRate.value(withMode: mode)
            dicoOfRandomVariable[.stockRate]   = stockRate.value(withMode: mode)
            return dicoOfRandomVariable
        }
        
        /// Définir une valeur pour la variable aléatoire avant un rejeu
        /// - Parameter value: nouvelle valeure à rejouer
        fileprivate mutating func setRandomValue(to values: DictionaryOfRandomVariable) {
            inflation.setRandomValue(to: values[.inflation]!)
            securedRate.setRandomValue(to: values[.securedRate]!)
            stockRate.setRandomValue(to: values[.stockRate]!)
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .inflation:
                        dico[randomVariable] = inflation.randomHistory
                    case .securedRate:
                        dico[randomVariable] = securedRate.randomHistory
                    case .stockRate:
                        dico[randomVariable] = stockRate.randomHistory
                }
            }
            return dico
        }
    }
    
    // MARK: - Modèles statistiques de générateurs aléatoires + échantillons tirés pour une simulation
    public final class Model: JsonCodableToFolderP, JsonCodableToBundleP, InitializableP, EconomyModelProviderP {
        enum CodingKeys: CodingKey { // swiftlint:disable:this nesting
            case randomizers
        }
        // MARK: - Properties
        
        public var randomizers : RandomizersModel // les modèles de générateurs aléatoires
        var firstYearSampled   : Int = 0
        // utilisés uniqument si mode == .random && randomizers.simulateVolatility
        var securedRateSamples : [Double] = [ ] // les échatillons tirés aléatoirement à chaque simulation
        var stockRateSamples   : [Double] = [ ] // les échatillons tirés aléatoirement à chaque simulation
        
        // MARK: - Iitializers
        
        /// Créer un clone
        /// - Parameter original: l'original à cloner
        public init?(from original: Economy.Model?) {
            guard let original = original else {
                return nil
            }
            self.randomizers        = original.randomizers
            self.firstYearSampled   = original.firstYearSampled
            self.securedRateSamples = original.securedRateSamples
            self.stockRateSamples   = original.stockRateSamples
        }
        
        // MARK: - Methods
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public final func initialized() -> Self {
            randomizers = randomizers.initialized()
            return self
        }
        
        /// Remettre à zéro les historiques des tirages aléatoires
        /// - Note : Appeler avant de lancer une simulation
        public final func resetRandomHistory() {
            randomizers.resetRandomHistory()
        }
        
        public final func currentRandomizersValues(withMode: SimulationModeEnum) -> DictionaryOfRandomVariable {
            return randomizers.current(withMode: withMode)
        }
        
        /// Retourne les taux pour une année donnée
        /// - Parameters:
        ///   - year: année
        ///   - mode: mode de simulation : Monté-Carlo ou Détermnisite
        /// - Returns: Taux Oblig / Taux Action [0%, 100%]
        /// - Important: Les taux changent d'une année à l'autre seuelement en mode Monté-Carlo
        ///             et si la ‘volatilité‘ à été activée dans le fichier de conf
        public final func rates(in year            : Int,
                                withMode mode      : SimulationModeEnum,
                                simulateVolatility : Bool)
        -> (securedRate : Double,
            stockRate   : Double) {
            if mode == .random && simulateVolatility {
                // utiliser la séquence tirée aléatoirement au début du run par la fonction 'generateRandomSamples'
                return (securedRate : securedRateSamples[year - firstYearSampled],
                        stockRate   : stockRateSamples[year - firstYearSampled])
                
            } else {
                // utiliser la valeur constante pour toute la durée du run
                return (securedRate : randomizers.securedRate.value(withMode: mode),
                        stockRate   : randomizers.stockRate.value(withMode: mode))
            }
        }
        
        /// Retourne les taux moyen pour toute la durée de la simulation
        /// - Parameters:
        ///   - mode: mode de simulation : Monté-Carlo ou Détermnisite
        /// - Returns: Taux Oblig / Taux Action [0%, 100%]
        public final func rates(withMode mode : SimulationModeEnum)
        -> (securedRate : Double,
            stockRate   : Double) {
            (securedRate : randomizers.securedRate.value(withMode: mode),
             stockRate   : randomizers.stockRate.value(withMode: mode))
        }
        
        /// Tirer au hazard les taux pour chaque année
        /// - Parameters:
        ///   - simulateVolatility: true = simuler la volatilité en faisant un tirage différent pour chaque année
        ///   - averageMode: détermine quelle sera la valeure moyenne retenue (déterministe ou aléatoire).
        ///                   Utilisé seulement si `simulateVolatility`= true
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        /// - Note: comportement différent selon que la volatilité doit être prise en compte ou pas
        private final func generateRandomSamples(averageMode        : SimulationModeEnum,
                                                 simulateVolatility : Bool,
                                                 firstYear          : Int,
                                                 lastYear           : Int) throws {
            guard lastYear >= firstYear else {
                customLog.log(level: .fault, "generateRandomSamples: lastYear < firstYear")
                throw ModelError.outOfBounds
            }
            firstYearSampled        = firstYear
            securedRateSamples      = []
            stockRateSamples        = []
            if simulateVolatility {
                for _ in firstYear...lastYear {
                    securedRateSamples
                        .append(Random.default.normal.next(mu   : randomizers.securedRate.value(withMode: averageMode),
                                                           sigma: randomizers.securedVolatility))
                    stockRateSamples
                        .append(Random.default.normal.next(mu   : randomizers.stockRate.value(withMode: averageMode),
                                                           sigma: randomizers.stockVolatility))
                }
            }
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        /// - Parameters:
        ///   - simulateVolatility: true = simuler la volatilité en faisant un tirage différent pour chaque année
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        /// - Returns: dictionnaire des échantillon de valeurs moyennes pour le prochain Run
        /// - Note :
        ///   - Appeler avant de lancer un Run de simulation
        ///   - Comportement différent selon que la volatilité doit être prise en compte ou pas
        /// - Throws:
        @discardableResult
        public final func nextRun(simulateVolatility : Bool,
                                  firstYear          : Int,
                                  lastYear           : Int) throws -> DictionaryOfRandomVariable {
            // tirer au hazard une nouvelle valeure moyenne pour le prochain run
            let dico = randomizers.next()
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            try generateRandomSamples(averageMode        : .random,
                                      simulateVolatility : simulateVolatility,
                                      firstYear          : firstYear,
                                      lastYear           : lastYear)
            return dico
        }
        
        /// Définir une valeur pour chaque variable aléatoire avant un rejeu
        /// - Parameters:
        ///   - values: nouvelles valeure sà rejouer
        ///   - simulateVolatility: true = simuler la volatilité en faisant un tirage différent pour chaque année
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        /// - Note :
        ///   - Appeler avant de rejouer un Run de simulation
        ///   - Comportement différent selon que la volatilité doit être prise en compte ou pas
        /// - Throws:
        public final func setRandomValue(to values          : DictionaryOfRandomVariable,
                                         simulateVolatility : Bool,
                                         firstYear          : Int,
                                         lastYear           : Int) throws {
            // Définir une valeur pour chaque variable aléatoire avant un rejeu
            randomizers.setRandomValue(to: values)
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            try generateRandomSamples(averageMode        : .random,
                                      simulateVolatility : simulateVolatility,
                                      firstYear          : firstYear,
                                      lastYear           : lastYear)
        }
        
        public final func inflation(withMode simulationMode: SimulationModeEnum) -> Double {
            randomizers.inflation.value(withMode: simulationMode)
        }
    }
    
    // MARK: - Static Properties
    
    public static var defaultFileName: String = "EconomyModelConfig.json"
    
    // MARK: - Properties
    
    public var model         : Model?
    public var persistenceSM : PersistenceStateMachine
    
    public var inflation: Double { // [0%, 100%]
        get { model!.randomizers.inflation.value(withMode: .deterministic) }
        set {
            model?.randomizers.inflation.defaultValue = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    public var securedRate: Double { // [0%, 100%]
        get { model!.randomizers.securedRate.value(withMode: .deterministic) }
        set {
            model?.randomizers.securedRate.defaultValue = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    public var stockRate: Double { // [0%, 100%]
        get { model!.randomizers.stockRate.value(withMode: .deterministic) }
        set {
            model?.randomizers.stockRate.defaultValue = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    public var securedVolatility: Double { // [0%, 100%]
        get { model!.randomizers.securedVolatility }
        set {
            model?.randomizers.securedVolatility = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    public var stockVolatility: Double { // [0%, 100%]
        get { model!.randomizers.stockVolatility }
        set {
            model?.randomizers.stockVolatility = newValue
            // mémoriser la modification
            persistenceSM.process(event: .onModify)
        }
    }
    
    // MARK: - Initializer
    
    /// Initialize seulement la StateMachine.
    /// L'objet ainsi obtenu n'est pas utilisable en l'état car le modèle n'est pas initialiser.
    /// Pour pouvoir obtenir un objet utilisable il faut utiliser un des autres init().
    /// Cet init() n'est utile que pour pouvoir créer un StateObject dans App.main()
    public init() {
        self.persistenceSM = PersistenceStateMachine()
    }

    /// Créer un clone
    /// - Parameter original: l'original à cloner
    public init(from original: Economy) {
        var clone = original
        clone.model = Economy.Model(from: original.model)
        self = clone
    }
}
