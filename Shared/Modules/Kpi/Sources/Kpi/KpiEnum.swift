//
//  KPIEnum.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/05/2021.
//

import Foundation
import AppFoundation
import Persistence

// MARK: - Enumération des KPI

public enum KpiEnum: Int, PickableEnumP, Codable, Hashable {
    case minimumAdultsAssetExcludinRealEstates = 0
    case assetAt1stDeath
    case assetAt2ndtDeath
    case netSuccessionAt2ndDeath
    case successionTaxesAt1stDeath
    case successionTaxesAt2ndDeath

    // properties
    
    var id: Int {
        return self.rawValue
    }
    
    public var pickerString: String {
        switch self {
            case .minimumAdultsAssetExcludinRealEstates:
                return "Actif Financier Minimum"
            case .assetAt1stDeath:
                return "Actif au Premier Décès"
            case .assetAt2ndtDeath:
                return "Actif au Dernier Décès"
            case .netSuccessionAt2ndDeath: // KPI #4
                return "Héritage net des enfants"
            case .successionTaxesAt1stDeath:  // KPI #5
                return "Droits succession enfants 1er décès"
            case .successionTaxesAt2ndDeath:  // KPI #6
                return "Droits succession enfants total"
        }
    }
    
    public var note: String {
        switch self {
            case .minimumAdultsAssetExcludinRealEstates:
                return """
                    Valeur minimale atteinte dans le temps pour l'ACTIF NET des ADULTES (hors immobilier physique) :
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
            case .netSuccessionAt2ndDeath:
                return """
                    Héritage total net reçu par les enfants au dernier décès des parents.
                    """
            case .successionTaxesAt1stDeath:
                return """
                    Droits de succession dûs par les enfants au premier décès d'un parent.
                    """
            case .successionTaxesAt2ndDeath:
                return """
                    Droits de succession dûs par les enfants au dernier décès des parents.
                    """
        }
    }
}
