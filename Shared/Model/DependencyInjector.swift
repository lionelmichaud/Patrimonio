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
import FamilyModel
import LifeExpense
import SimulationAndVisitors

/// Injecte les dépendances dans les différents objets du modèle utilisateur qui en ont besoin
struct DependencyInjector {

    /// Gérer les dépendances entre le Modèle et les **Struct** d'objets applicatifs qui en dépendent
    ///
    /// - Important: Cette méthode doit être apellée quand les sous-modèles suivants changent:
    ///  * fiscalModel
    ///  * socioEconomyModel
    ///  * economyModel
    ///
    /// - Parameter model: Le modèle qui a évolué
    ///
    static func updateStaticDependencies(to model: Model) {
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
    
    /// Gérer les dépendances entre le Modèle et les **Struct** d'objets applicatifs qui en dépendent
    /// mais aussi la dépendance des membres de la famille au modèle.
    /// Fait un reset de la Simulation pour annulé tous les résultats antérieurs.
    ///
    /// - Parameter model: Le modèle qui a évolué
    ///
    static func updateDependenciesToModel(model      : Model,
                                          family     : Family,
                                          simulation : Simulation) {
        // gérer les dépendances entre le Modèle et les objets applicatifs
        updateStaticDependencies(to: model)

        // mettre à jour les membres de la famille existants avec les nouvelles valeurs
        family.members.initialize(using: model)
        family.members.persistenceSM.process(event: .onModify)

        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
    }
}
