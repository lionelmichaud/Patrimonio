//
//  Coordinator.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/05/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel
import ModelEnvironment
import Ownership
import AssetsModel

/// Injecte les dépendance dans les différents objets du modèle utilisateur qui en ont besoin
struct Coordinator {
    /// gérer les dépendances entre le Modèle et les objets applicatifs
    static func manageDependencies(to model: Model) {
        // Injection de Fiscal
        //   récupérer une copie du singleton
        let fiscalModel = Fiscal.model
        //   l'injecter dans les objets qui en dépendent
        SCPI.setFiscalModelProvider(fiscalModel)
        RealEstateAsset.setFiscalModelProvider(fiscalModel)
        PeriodicInvestement.setFiscalModelProvider(fiscalModel)
        FreeInvestement.setFiscalModelProvider(fiscalModel)
        Ownership.setDemembrementProviderP(fiscalModel.demembrement)

        // Injection de SocioEconomy
        LifeExpense.setExpensesUnderEvaluationRateProvider(model.socioEconomyModel)
        
        // Injection de Economy
        SCPI.setInflationProvider(model.economyModel)
        PeriodicInvestement.setEconomyModelProvider(model.economyModel)
        FreeInvestement.setEconomyModelProvider(model.economyModel)
    }
}
