//
//  Economy.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import AppFoundation
import Statistics

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Economy")

// MARK: - DI: Protocol InflationProviderProtocol

public protocol InflationProviderProtocol {
    func inflation(withMode simulationMode: SimulationModeEnum) -> Double
}

public protocol FinancialRatesProviderProtocol {
    func rates(in year            : Int,
               withMode mode      : SimulationModeEnum,
               simulateVolatility : Bool)
    -> (securedRate : Double,
        stockRate   : Double)
    
    func rates(withMode mode : SimulationModeEnum)
    -> (securedRate : Double,
        stockRate   : Double)
}

public typealias EconomyModelProviderProtocol = InflationProviderProtocol & FinancialRatesProviderProtocol

// MARK: - SINGLETON: Economy Model

public struct Economy {
    
    // MARK: - Nested Types
    
    public enum ModelError: Error {
        case outOfBounds
    }
    
    public enum RandomVariable: String, PickableEnum {
        case inflation   = "Inflation"
        case securedRate = "Rendements Sûrs"
        case stockRate   = "Rendements Actions"
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public typealias DictionaryOfRandomVariable = [RandomVariable: Double]
    
    // MARK: - Modèles statistiques de générateurs aléatoires
    public struct RandomizersModel: BundleCodable {
        public static var defaultFileName : String = "EconomyModelConfig.json"
        
        // MARK: - Properties
        
        public var inflation   : ModelRandomizer<BetaRandomGenerator>
        public var securedRate : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        public var stockRate   : ModelRandomizer<BetaRandomGenerator> // moyenne annuelle
        //var simulateVolatility: Bool = false
        var securedVolatility : Double // % [0, 100]
        var stockVolatility   : Double // % [0, 100]
        
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
    public class Model: EconomyModelProviderProtocol {
        
        // MARK: - Properties
        
        public var randomizers        : RandomizersModel // les modèles de générateurs aléatoires
        var firstYearSampled   : Int = 0
        // utilisés uniqument si mode == .random && randomizers.simulateVolatility
        var securedRateSamples : [Double] = [ ] // les échatillons tirés aléatoirement à chaque simulation
        var stockRateSamples   : [Double] = [ ] // les échatillons tirés aléatoirement à chaque simulation
        
        // MARK: - Methods
        
        init() {
            self.randomizers = RandomizersModel().initialized()
        }
        
        /// A utiliser uniquement pour les Tests Unitaires
        /// - Parameter fromBundle: le Bundle dans lequel chercher le fichier de configuration JSON
        init(fromBundle: Bundle) {
            self.randomizers = RandomizersModel(fromBundle: fromBundle).initialized()
        }

        // MARK: - Methods
        
        /// Retourne les taux pour une année donnée
        /// - Parameters:
        ///   - year: année
        ///   - mode: mode de simulation : Monté-Carlo ou Détermnisite
        /// - Returns: Taux Oblig / Taux Action
        /// - Important: Les taux changent d'une année à l'autre seuelement en mode Monté-Carlo
        ///             et si la ‘volatilité‘ à été activée dans le fichier de conf
        public func rates(in year            : Int,
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
        /// - Returns: Taux Oblig / Taux Action
        public func rates(withMode mode : SimulationModeEnum)
        -> (securedRate : Double,
            stockRate   : Double) {
            (securedRate : randomizers.securedRate.value(withMode: mode),
             stockRate   : randomizers.stockRate.value(withMode: mode))
        }
        
        /// Tirer au hazard les taux pour chaque année
        /// - Parameters:
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        ///   - withMode: mode de simulation qui détermine quelle sera la valeure moyenne retenue
        /// - Note: comportement différent selon que la volatilité doit être prise en compte ou pas
        private func generateRandomSamples(withMode           : SimulationModeEnum,
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
            if withMode == .random && simulateVolatility {
                for _ in firstYear...lastYear {
                    securedRateSamples.append(Random.default.normal.next(mu   : randomizers.securedRate.value(withMode: withMode),
                                                                         sigma: randomizers.securedVolatility))
                    stockRateSamples.append(Random.default.normal.next(mu   : randomizers.stockRate.value(withMode: withMode),
                                                                       sigma: randomizers.stockVolatility))
                }
            }
        }
        
        /// Remettre à zéro les historiques des tirages aléatoires
        /// - Note : Appeler avant de lancer une simulation
        public func resetRandomHistory() {
            randomizers.resetRandomHistory()
        }
        
        /// Générer les nombres aléatoires suivants et retourner leur valeur pour historisation
        /// - Parameters:
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        /// - Returns: dictionnaire des échantillon de valeurs moyennes pour le prochain Run
        /// - Note : Appeler avant de lancer un Run de simulation
        public func nextRun(withMode           : SimulationModeEnum,
                            simulateVolatility : Bool,
                            firstYear          : Int,
                            lastYear           : Int) throws -> DictionaryOfRandomVariable {
            guard lastYear >= firstYear else {
                customLog.log(level: .fault, "nextRun: lastYear < firstYear")
                throw ModelError.outOfBounds
            }
            // tirer au hazard une nouvelle valeure moyenne pour le prochain run
            let dico = randomizers.next()
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            try generateRandomSamples(withMode           : withMode,
                                      simulateVolatility : simulateVolatility,
                                      firstYear          : firstYear,
                                      lastYear           : lastYear)
            return dico
        }
        
        /// Définir une valeur pour chaque variable aléatoire avant un rejeu
        /// - Parameters:
        ///   - value: nouvelle valeure à rejouer
        ///   - firstYear: première année
        ///   - lastYear: dernière année
        /// - Note : Appeler avant de rejouer un Run de simulation
        public func setRandomValue(to values          : DictionaryOfRandomVariable,
                                   withMode           : SimulationModeEnum,
                                   simulateVolatility : Bool,
                                   firstYear          : Int,
                                   lastYear           : Int) throws {
            // Définir une valeur pour chaque variable aléatoire avant un rejeu
            randomizers.setRandomValue(to: values)
            // à partir de la nouvelle valeure moyenne, tirer au hazard une valeur pour chaque année
            try generateRandomSamples(withMode           : withMode,
                                      simulateVolatility : simulateVolatility,
                                      firstYear          : firstYear,
                                      lastYear           : lastYear)
        }
        
        public func inflation(withMode simulationMode: SimulationModeEnum) -> Double {
            randomizers.inflation.value(withMode: simulationMode)
        }
    }
    
    // MARK: - Static Properties
    
    public static var model: Model = Model()
    
    // MARK: - Initializer
    
    private init() {
    }
}
