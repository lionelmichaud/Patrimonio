//
//  Coordinator.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/05/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import ModelEnvironment
import Ownership
import AssetsModel

/// Injecte les dépendance dans les différents objets du modèle utilisateur qui en ont besoin
struct DependencyInjector {
    /// gérer les dépendances entre le Modèle et les objets applicatifs
    static func manageDependencies(to model: Model) {
        // Injection de Fiscal
        RealEstateAsset.setFiscalModelProvider(model.fiscalModel)
        SCPI.setFiscalModelProvider(model.fiscalModel)
        PeriodicInvestement.setFiscalModelProvider(model.fiscalModel)
        FreeInvestement.setFiscalModelProvider(model.fiscalModel)
        Ownership.setDemembrementProviderP(model.fiscalModel.demembrement)

        // Injection de SocioEconomy
        LifeExpense.setExpensesUnderEvaluationRateProvider(model.socioEconomyModel)
        
        // Injection de Economy
        SCPI.setInflationProvider(model.economyModel)
        PeriodicInvestement.setEconomyModelProvider(model.economyModel)
        FreeInvestement.setEconomyModelProvider(model.economyModel)
    }
}
