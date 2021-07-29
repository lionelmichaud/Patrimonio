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

    @Published var economy: Economy
    var economyModel: Economy.Model {
        economy.model!
    }
    
    var isModified: Bool {
        humanLife.isModified || retirement.isModified || economy.isModified
    }
    
    // MARK: - Initialization
    
    /// Cet init() n'est utile que pour pouvoir créer un StateObject dans AppMain
    /// Pour pouvoir utiliser cet objet il faut d'abord initialiser les modèles avec
    /// une méthode: init(fromBundle bundle: Bundle) ou loadFromJSON(fromFolder folder: Folder)
    /// - Note: Nécessaire pour une initialization dans AppMain au lancement de l'application
    init() {
        humanLife  = HumanLife()
        retirement = Retirement()
        economy    = Economy()
    }
    
    /// Charger tous les modèles à partir des fichiers JSON contenu de fichiers contenus dans le bundle `bundle`
    /// - Parameters:
    ///   - bundle: le bundle dans lequel chercher les fichiers JSON
    init(fromBundle bundle: Bundle) {
        humanLife  = HumanLife(fromBundle: Bundle.main)
        retirement = Retirement(fromBundle: Bundle.main)
        economy    = Economy(fromBundle: Bundle.main)

        // gérer les dépendances
        manageDependencies()
    }

    // MARK: - Methods

    /// Charger tous les modèles à partir des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func loadFromJSON(fromFolder folder: Folder) throws {
        humanLife  = try HumanLife(fromFolder: folder)
        retirement = try Retirement(fromFolder: folder)
        economy    = try Economy(fromFolder: folder)

        // gérer les dépendances
        manageDependencies()
    }

    /// Enregistrer tous les modèles dans des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func saveAsJSON(toFolder folder: Folder) throws {
        try humanLife.saveAsJSON(toFolder: folder)
        try retirement.saveAsJSON(toFolder: folder)
        try economy.saveAsJSON(toFolder: folder)
    }
    
    /// Gérer les dépendances entre modèles
    func manageDependencies() {
        /// Injection de Fiscal
        // récupérer une copie du singleton
        let fiscalModel = Fiscal.model
        // l'injecter dans les singletons qui en dépendent
        LayoffCompensation.setFiscalModel(fiscalModel)
        UnemploymentCompensation.setFiscalModel(fiscalModel)
        retirement.model!.regimeAgirc.setFiscalModel(fiscalModel)
        retirement.model!.regimeGeneral.setFiscalModel(fiscalModel)
        SCPI.setFiscalModelProvider(fiscalModel)
        PeriodicInvestement.setFiscalModelProvider(fiscalModel)
        FreeInvestement.setFiscalModelProvider(fiscalModel)
        
        /// Injection de SocioEconomy
        // récupérer une copie du singleton
        let socioEconomyModel = SocioEconomy.model
        // l'injecter dans les singletons qui en dépendent
        retirement.model!.regimeAgirc.setPensionDevaluationRateProvider(socioEconomyModel)
        retirement.model!.regimeGeneral.setSocioEconomyModel(socioEconomyModel)
        
        /// Injection de Economy
        // l'injecter dans les singletons qui en dépendent
        SCPI.setInflationProvider(economyModel)
        PeriodicInvestement.setEconomyModelProvider(economyModel)
        FreeInvestement.setEconomyModelProvider(economyModel)
    }
}
