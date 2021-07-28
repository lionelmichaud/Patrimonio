//
//  Model.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/07/2021.
//

import Foundation
import FiscalModel
import RetirementModel
import UnemployementModel
import EconomyModel
import SocioEconomyModel
import HumanLifeModel
import Files

/// Agregat des éléments du Model environmental
final class Model: ObservableObject {

    // MARK: - Properties

    @Published var humanLife: HumanLife
    var humanLifeModel: HumanLife.Model {
        humanLife.model!
    }
    @Published var retirement: Retirement
    var retirementModel: Retirement.Model {
        retirement.model!
    }

    var isModified: Bool {
        humanLife.isModified || retirement.isModified
    }
    
    // MARK: - Initialization
    
    /// Note: nécessaire pour une initialization dans App au lancement de l'application
    init() {
        humanLife  = HumanLife()
        retirement = Retirement()
        
        /// gérer les dépendances
        
        // récupérer une copie du singleton
        let fiscalModel = Fiscal.model
        // l'injecter dans les singletons qui en dépendent
        LayoffCompensation.setFiscalModel(fiscalModel)
        UnemploymentCompensation.setFiscalModel(fiscalModel)
        RegimeAgirc.setFiscalModel(fiscalModel)
        RegimeGeneral.setFiscalModel(fiscalModel)
        SCPI.setFiscalModelProvider(fiscalModel)
        PeriodicInvestement.setFiscalModelProvider(fiscalModel)
        FreeInvestement.setFiscalModelProvider(fiscalModel)
        
        // récupérer une copie du singleton
        let socioEconomyModel = SocioEconomy.model
        // l'injecter dans les singletons qui en dépendent
        RegimeAgirc.setPensionDevaluationRateProvider(socioEconomyModel)
        RegimeGeneral.setSocioEconomyModel(socioEconomyModel)
        
        // récupérer une copie du singleton
        let economyModel = Economy.model
        SCPI.setInflationProvider(economyModel)
        PeriodicInvestement.setEconomyModelProvider(economyModel)
        FreeInvestement.setEconomyModelProvider(economyModel)
    }
    
    /// Charger tous les modèles à partir des fichiers JSON contenu de fichiers contenus dans le bundle `bundle`
    /// - Parameters:
    ///   - bundle: le bundle dans lequel chercher les fichiers JSON
    init(fromBundle bundle: Bundle) {
        humanLife  = HumanLife(fromBundle: Bundle.main)
        retirement = Retirement(fromBundle: Bundle.main)
    }

    // MARK: - Methods

    /// Charger tous les modèles à partir des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func loadFromJSON(fromFolder folder: Folder) throws {
        humanLife  = try HumanLife(fromFolder: folder)
        retirement = try Retirement(fromFolder: folder)
    }

    /// Enregistrer tous les modèles dans des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func saveAsJSON(toFolder folder: Folder) throws {
        try humanLife.saveAsJSON(toFolder: folder)
        try retirement.saveAsJSON(toFolder: folder)
    }
}
