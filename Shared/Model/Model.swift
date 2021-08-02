//
//  Model.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/07/2021.
//

import Foundation
import os
import FiscalModel
import RetirementModel
import UnemployementModel
import EconomyModel
import SocioEconomyModel
import HumanLifeModel
import Files

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Model")

/// Agregat des éléments du Model environmental
final class Model: ObservableObject, CustomStringConvertible {

    // MARK: - Properties
    
    @Published var humanLife: HumanLife
    var humanLifeModel: HumanLife.Model {
        if humanLife.model == nil {
            customLog.log(level: .fault, "Tentative d'accès au modèle HumanLife.model : non initialisé")
            fatalError()
        } else {
            return humanLife.model!
        }
    }
    
    @Published var retirement: Retirement
    var retirementModel: Retirement.Model {
        if retirement.model == nil {
            customLog.log(level: .fault, "Tentative d'accès au modèle Retirement.model : non initialisé")
            fatalError()
        } else {
            return retirement.model!
        }
    }
    
    @Published var economy: Economy
    var economyModel: Economy.Model {
        if economy.model == nil {
            customLog.log(level: .fault, "Tentative d'accès au modèle Economy.model : non initialisé")
            fatalError()
        } else {
            return economy.model!
        }
    }
    
    @Published var socioEconomy: SocioEconomy
    var socioEconomyModel: SocioEconomy.Model {
        if socioEconomy.model == nil {
            customLog.log(level: .fault, "Tentative d'accès au modèle SocioEconomy.model : non initialisé")
            fatalError()
        } else {
            return socioEconomy.model!
        }
    }
    
    @Published var unemployment: Unemployment
    var unemploymentModel: Unemployment.Model {
        if unemployment.model == nil {
            customLog.log(level: .fault, "Tentative d'accès au modèle Unemployment.model : non initialisé")
            fatalError()
        } else {
            return unemployment.model!
        }
    }
    
    var isModified: Bool {
        humanLife.isModified || retirement.isModified
            || economy.isModified || socioEconomy.isModified || unemployment.isModified
    }
    
    var description: String {
        return """
        
        MODEL: HumanLife
        - Etat:   \(humanLife.persistenceState)
        - Modèle: \(humanLife.model == nil ? "non initialisé" : "initialisé")

        MODEL: Retirement
        - Etat:   \(retirement.persistenceState)
        - Modèle: \(retirement.model == nil ? "non initialisé" : "initialisé")

        MODEL: Economy
        - Etat:   \(economy.persistenceState)
        - Modèle: \(economy.model == nil ? "non initialisé" : "initialisé")

        MODEL: SocioEconomy
        - Etat:   \(socioEconomy.persistenceState)
        - Modèle: \(socioEconomy.model == nil ? "non initialisé" : "initialisé")

        MODEL: Unemployment
        - Etat:   \(unemployment.persistenceState)
        - Modèle: \(unemployment.model == nil ? "non initialisé" : "initialisé")

        """
    }
    
    // MARK: - Initialization
    
    /// Cet init() n'est utile que pour pouvoir créer un StateObject dans AppMain
    /// Pour pouvoir utiliser cet objet il faut d'abord initialiser les modèles avec
    /// une méthode: init(fromBundle bundle: Bundle) ou loadFromJSON(fromFolder folder: Folder)
    /// - Note: Nécessaire pour une initialization dans AppMain au lancement de l'application
    init() {
        humanLife    = HumanLife()
        retirement   = Retirement()
        economy      = Economy()
        socioEconomy = SocioEconomy()
        unemployment = Unemployment()
    }
    
    /// Charger tous les modèles à partir des fichiers JSON contenu de fichiers contenus dans le bundle `bundle`
    /// Gérer les dépendances internes au Model (entre les sous-modèle).
    /// - Warning: les dépendance externes entre le Model et les objets applicatifs doivent
    ///                        être gérées en dehors de cette méthode.
    /// - Parameters:
    ///   - bundle: le bundle dans lequel chercher les fichiers JSON
    init(fromBundle bundle: Bundle) {
        humanLife    = HumanLife(fromBundle    : Bundle.main)
        retirement   = Retirement(fromBundle   : Bundle.main)
        economy      = Economy(fromBundle      : Bundle.main)
        socioEconomy = SocioEconomy(fromBundle : Bundle.main)
        unemployment = Unemployment(fromBundle : Bundle.main)

        // gérer les dépendances
        manageInternalDependencies()
    }

    // MARK: - Methods

    /// Charger tous les modèles à partir des fichiers JSON contenu dans le `folder`
    /// Gérer les dépendances internes au Model (entre les sous-modèle).
    /// - Warning: les dépendance externes entre le Model et les objets applicatifs doivent
    ///                        être gérées en dehors de cette méthode.
    /// - Parameter folder: dossier chargé par l'utilisateur
    func loadFromJSON(fromFolder folder: Folder) throws {
        humanLife    = try HumanLife(fromFolder    : folder)
        retirement   = try Retirement(fromFolder   : folder)
        economy      = try Economy(fromFolder      : folder)
        socioEconomy = try SocioEconomy(fromFolder : folder)
        unemployment = try Unemployment(fromFolder : folder)

        // gérer les dépendances
        manageInternalDependencies()
    }

    /// Enregistrer tous les modèles dans des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func saveAsJSON(toFolder folder: Folder) throws {
        try humanLife.saveAsJSON(toFolder: folder)
        try retirement.saveAsJSON(toFolder: folder)
        try economy.saveAsJSON(toFolder: folder)
        try socioEconomy.saveAsJSON(toFolder: folder)
        try unemployment.saveAsJSON(toFolder: folder)
    }
    
    /// Enregistrer tous les modèles dans des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func saveAsJSON(toBundle bundle: Bundle) throws {
        humanLife.saveAsJSON(toBundle: bundle)
        retirement.saveAsJSON(toBundle: bundle)
        economy.saveAsJSON(toBundle: bundle)
        socioEconomy.saveAsJSON(toBundle: bundle)
        unemployment.saveAsJSON(toBundle: bundle)
    }

    /// Gérer les dépendances entre modèles
    func manageInternalDependencies() {
        /// Injection de Fiscal
        // récupérer une copie du singleton
        let fiscalModel = Fiscal.model
        // l'injecter dans les objets qui en dépendent
        unemployment.model!.indemniteLicenciement.setFiscalModel(fiscalModel)
        unemployment.model!.allocationChomage.setFiscalModel(fiscalModel)
        retirement.model!.regimeAgirc.setFiscalModel(fiscalModel)
        retirement.model!.regimeGeneral.setFiscalModel(fiscalModel)
        
        /// Injection de SocioEconomy
        retirement.model!.regimeAgirc.setPensionDevaluationRateProvider(socioEconomyModel)
        retirement.model!.regimeGeneral.setSocioEconomyModel(socioEconomyModel)
    }
}
