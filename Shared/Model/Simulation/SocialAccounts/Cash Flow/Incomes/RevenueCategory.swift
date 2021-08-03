//
//  IncomeCategory.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Catégories de revenus

/// Catégories de revenus
enum RevenueCategory: String, PickableEnumP, Codable, Hashable {
    case workIncomes        = "Revenu Travail"
    case pensions           = "Pension"
    case layoffCompensation = "Indemnité de licenciement"
    case unemployAlloc      = "Allocation Chomage"
    case financials         = "Revenu Financier" // capitalisés
    case scpis              = "Revenu SCPI"
    case scpiSale           = "Vente SCPI" // capitalisés
    case realEstateRents    = "Revenu Location"
    case realEstateSale     = "Vente Immeuble" // capitalisés
    
    // properties
    
    var pickerString: String {
        return self.rawValue
    }

    /// True si la catégorie de revenus est incorporée au NetCashFlow commun de fin d'année
    /// et donc ré-investi dans un actif sans distinction de son propriétaire
    var isPartOfCashFlow: Bool {
        switch self {
            case .workIncomes, .pensions,
                 .layoffCompensation, .unemployAlloc,
                 .scpis, .realEstateRents:
                return true
                
            case .financials, .scpiSale, .realEstateSale:
                return false
        }
    }
}
