//
//  Patrimoine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import os
import AppFoundation
import Statistics
import Files
import Ownership
import AssetsModel
import Liabilities

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Patrimoin")

enum CashFlowError: Error {
    case notEnoughCash(missingCash: Double)
}

// MARK: - Patrimoine constitué d'un Actif et d'un Passif
final class Patrimoin: ObservableObject {
    
    // MARK: - Nested Type
    
    struct Memento {
        private(set) var assets      : Assets
        private(set) var liabilities : Liabilities
        init(assets      : Assets,
             liabilities : Liabilities) {
            self.assets      = assets
            self.liabilities = liabilities
        }
    }
    
    // MARK: - Type Properties
    
    // doit être injecté depuis l'extérieur avant toute instanciation de la classe
    static var family: Family?
    
    // MARK: - Type Methods
    
    /// Définir le mode de simulation à utiliser pour tous les calculs futurs
    /// - Parameter simulationMode: mode de simulation à utiliser
    static func setSimulationMode(to simulationMode : SimulationModeEnum) {
        Assets.setSimulationMode(to: simulationMode)
    }
    
    // MARK: - Properties
    
    @Published var assets      = Assets()
    @Published var liabilities = Liabilities()
//    @Published var isModified  = false
    var memento: Memento?

//    private var subscriptions = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var isModified: Bool {
        return
            assets.isModified ||
            liabilities.isModified
    }

    // MARK: - Initializers
    
    /// Initialiser à vide
    /// - Note: Utilisé à la création de l'App, avant que le dossier n'ait été sélectionné
    init() {
        // mettre à jour la propriété comme si elle était calculée à l'aide de Combine
//        let assetsIsModified: ((Assets) -> Bool) = { assets in
//            return assets.isModified || self.liabilities.isModified
//        }
//        self.$assets.map(assetsIsModified).assign(to: \.isModified, on: self).store(in: &subscriptions)
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Note: Utilisé seulement pour les Tests
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    convenience init(fromFolder folder: Folder) throws {
        self.init()
        try self.assets      = Assets(fromFolder : folder,      with: Patrimoin.family)
        try self.liabilities = Liabilities(fromFolder : folder, with: Patrimoin.family)
    }
    
    // MARK: - Methods
    
    /// lire à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - model: modèle à utiliser pour initialiser les membres de la famille
    /// - Throws: en cas d'échec de lecture des données
    func loadFromJSON(fromFolder folder: Folder) throws {
        assets      = try Assets(fromFolder : folder,      with : Patrimoin.family)
        liabilities = try Liabilities(fromFolder : folder, with : Patrimoin.family)
        memento     = nil
    }
    
    func saveAsJSON(toFolder folder: Folder) throws {
        try assets.saveAsJSON(toFolder: folder)
        try liabilities.saveAsJSON(toFolder: folder)
    }
    
    func value(atEndOf year: Int) -> Double {
        assets.value(atEndOf: year) +
            liabilities.value(atEndOf: year)
    }
    
    /// Réinitialiser les valeurs courantes des investissements libres
    /// - Warning:
    ///   - Doit être appelée après le chargement d'un objet FreeInvestement depuis le fichier JSON
    ///   - Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func resetFreeInvestementCurrentValue() {
        assets.initializeFreeInvestementCurrentValue()
    }
    
    /// Sauvegarder l'état courant du Patrimoine
    /// - Warning: Doit être appelée avant toute simulation pouvant affecter le Patrimoine (succession)
    func saveState() {
        memento = Memento(assets      : assets,
                          liabilities : liabilities)
    }
    
    /// Recharger les actifs et passifs à partir  de la dernière sauvegarde pour repartir d'une situation initiale sans aucune modification
    /// - Warning: Doit être appelée après toute simulation ayant affectée le Patrimoine (succession)
    func restoreState() {
        guard let memento = memento else {
            customLog.log(level: .fault, "patrimoine.restore: tentative de restauration d'un patrimoine non sauvegardé")
            fatalError("patrimoine.restore: tentative de restauration d'un patrimoine non sauvegardé")
        }
        assets      = memento.assets
        liabilities = memento.liabilities
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (OwnableP) throws -> Void) rethrows {
        try assets.forEachOwnable(body)
        try liabilities.forEachOwnable(body)
    }

    /// Calcule  la valeur nette taxable du patrimoine immobilier de la famille selon la méthode de calcul choisie
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - year: année d'évaluation
    ///   - evaluationMethod: méthode d'évalution des biens
    /// - Returns: assiette nette fiscale calculée selon la méthode choisie
    func realEstateValue(atEndOf year     : Int,
                         evaluationMethod : EvaluationMethod) -> Double {
        assets.realEstateValue(atEndOf          : year,
                               for              : Patrimoin.family!,
                               evaluationMethod : evaluationMethod) +
            liabilities.realEstateValue(atEndOf          : year,
                                        for              : Patrimoin.family!,
                                        evaluationMethod : evaluationMethod)
    }
}

extension Patrimoin: CustomStringConvertible {
    var description: String {
        """

        PATRIMOINE:
        \(("Modifié:" + String(isModified)).withPrefixedSplittedLines("  "))
        \(assets.description.withPrefixedSplittedLines("  "))
        \(liabilities.description.withPrefixedSplittedLines("  "))
        """
    }
}
