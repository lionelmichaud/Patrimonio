//
//  Model.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/07/2021.
//

import Foundation
import HumanLifeModel
import Files

/// Agregat des éléments du Model environmental
final class Model: ObservableObject {

    // MARK: - Properties

    var humanLife      : HumanLife
    var humanLifeModel : HumanLife.Model {
        humanLife.model!
    }

    // MARK: - Initialization
    
    /// Note: nécessaire pour une initialization dans App au lancement de l'application
    init() {
        humanLife = HumanLife()
    }
    
    /// Charger tous les modèles à partir des fichiers JSON contenu de fichiers contenus dans le bundle `bundle`
    /// - Parameters:
    ///   - bundle: le bundle dans lequel chercher les fichiers JSON
    init(fromBundle bundle: Bundle) {
        humanLife = HumanLife(fromBundle: Bundle.main)
    }

    // MARK: - Methods

    /// Charger tous les modèles à partir des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func loadFromJSON(fromFolder folder: Folder) throws {
        humanLife = try HumanLife(fromFolder: folder)
    }

    /// Enregistrer tous les modèles dans des fichiers JSON contenu dans le `folder`
    /// - Parameter folder: dossier chargé par l'utilisateur
    func saveAsJSON(toFolder folder: Folder) throws {
        try humanLife.saveAsJSON(toFolder: folder)
    }
}
