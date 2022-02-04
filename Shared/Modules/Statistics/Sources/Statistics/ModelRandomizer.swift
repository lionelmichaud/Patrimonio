//
//  ModelRandomizer.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 26/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Model aléatoire

public struct ModelRandomizer<R: RandomGeneratorP>: Codable, VersionableP
where R: Codable,
      R.Number == Double {

    enum CodingKeys: CodingKey {
        case version, name, rndGenerator, defaultValue
    }
    
    // MARK: - Properties

    public var version       : Version
    /// Nom de la valeur aléatoire
    public var name          : String
    /// Générateur aléatoire
    public var rndGenerator  : R
    /// Valeur par defaut déterministe
    public var defaultValue  : Double = 0
    /// Dernière valeur randomisée
    private var randomValue  : Double = 0
    /// Historique des tirages aléatoires
    public var randomHistory : [Double]?

    // MARK: - Methods
    
    /// Remettre à zéro les historiques des tirages aléatoires
    public mutating func resetRandomHistory() {
        randomHistory = []
    }
    
    /// Générer le nombre aléatoire suivant
    @discardableResult public mutating func next() -> Double {
        randomValue = Double(rndGenerator.next())
        if randomHistory == nil {
            randomHistory = []
        }
        randomHistory!.append(randomValue)
        return randomValue
    }
    
    /// Définir une valeur pour la variable aléaoitre avant un rejeu
    /// - Parameter value: nouvelle valeure à rejouer
    public mutating func setRandomValue(to value: Double) {
        randomValue = value
    }
    
    /// Returns a default value or a  random value depending on the value of simulationMode.mode
    public func value(withMode mode : SimulationModeEnum) -> Double {
        switch mode {
            case .deterministic:
                return defaultValue
                
            case .random:
                return randomValue
        }
    }
}
