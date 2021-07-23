//
//  SimulationKPIEnum.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
import AppFoundation

// MARK: - Enumération des KPI

enum SimulationKPIEnum: Int, PickableEnum, Codable, Hashable {
    case minimumAsset = 0
    case assetAt1stDeath
    case assetAt2ndtDeath
    
    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    var pickerString: String {
        switch self {
            case .minimumAsset:
                return "Actif Financier Minimum"
            case .assetAt1stDeath:
                return "Actif au Premier Décès"
            case .assetAt2ndtDeath:
                return "Actif au Dernier Décès"
        }
    }
    
    var note: String {
        switch self {
            case .minimumAsset:
                return """
                    Valeur minimale atteinte dans le temps pour l'ACTIF NET (hors immobilier physique) :
                     - Biens pris en compte: <<OwnershipNature>>
                     - Méthode d'évaluation: <<AssetEvaluationMethod>>
                    """
            case .assetAt1stDeath:
                return """
                    Valeur atteinte au 1er décès pour l'ACTIF NET (hors immobilier physique) :
                     - Biens pris en compte: <<OwnershipNature>>
                     - Méthode d'évaluation: <<AssetEvaluationMethod>>
                    """
            case .assetAt2ndtDeath:
                return """
                    Valeur atteinte au 2nd décès pour l'ACTIF NET (hors immobilier physique) :
                     - Biens pris en compte: <<OwnershipNature>>
                     - Méthode d'évaluation: <<AssetEvaluationMethod>>
                    """
        }
    }
}
