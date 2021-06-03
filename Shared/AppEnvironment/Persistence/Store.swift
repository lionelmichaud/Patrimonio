//
//  Store.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import Foundation
import os

// MARK: - STORE

class Store: ObservableObject {
    @Published var dossiers                     : DossierArray
    @Published var failedToLoadDossiers         : Bool
    @Published var failedToUpdateTemplateFolder : Bool
    // le dossier en cours d'utilisation
    var activeDossier : Dossier? {
        dossiers.first(where: { $0.isActive })
    }

    /// Charger la liste des Dossiers utilisateur et
    /// mettre à jour le répertoire des templates à partir du Bundle App Main
    init() {
        // charger tous les dossiers utilisateur
        do {
            var loadedDossiers = DossierArray()
            try loadedDossiers.load()
            self.dossiers = loadedDossiers
            self.failedToLoadDossiers = false
            
        } catch {
            self.dossiers = []
            self.failedToLoadDossiers = true
        }
        
        // mettre à jour le répertoire des templates à partir du Bundle App Main
        // ceici permet prendre en compte toute évolution de l'app et de ses templates
        do {
            try PersistenceManager.importTemplatesFromApp()
            self.failedToUpdateTemplateFolder = false
        } catch {
            self.failedToUpdateTemplateFolder = true
        }
    }

    /// Activer le dossier situé à l'index 'index'.
    /// Désativer tous les autres.
    func activate(dossierAtIndex index: Int) {
        for idx in dossiers.startIndex..<dossiers.endIndex {
            dossiers[idx].isActive = false
        }
        dossiers[index].isActive = true
    }
    
    /// Créer un nouveau Dossier
    /// - Parameters:
    ///   - name: nom du dossier
    ///   - note: note décrivant le dossier
    func createDossier(named name       : String,
                       annotatedBy note : String) throws {
        let newDossier = try Dossier(name: name,
                                     note: note)
        dossiers.append(newDossier)
    }

    /// Dupliquer un Dossier
    /// - Parameter dossier: Dossier à duspliquer
    func duplicate(_ dossier: Dossier) throws {
        let newDossier = try dossier.duplicate()
        dossiers.append(newDossier)
    }
    
    /// Supprimer le contenu du dossier et le directory associé
    func deleteDossier(atOffsets offsets: IndexSet) throws {
        try dossiers[offsets.first!].delete()
        dossiers.remove(atOffsets: offsets)
    }
}

extension Store: CustomStringConvertible {
    var description: String {
        var str = ""
        dossiers.forEach { dossier in
            str += String(describing: dossier).withPrefixedSplittedLines("  ") + "\n"
        }
        return str
    }
}
