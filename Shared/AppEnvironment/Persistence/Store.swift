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
    @Published var dossiers             : DossierArray
    @Published var failedToLoadDossiers : Bool
    // le dossier en cours d'utilisation
    var activeDossier : Dossier? {
        dossiers.first(where: { $0.isActive })
    }

    init() {
        do {
            var loadedDossiers = DossierArray()
            try loadedDossiers.load()
            self.dossiers = loadedDossiers
            self.failedToLoadDossiers = false
        } catch {
            self.dossiers = []
            self.failedToLoadDossiers = true
        }
    }

    /// Charger la liste des Dossiers
//    func load() throws {
//        do {
//            try dossiers.load()
//            failedToLoadDossiers = false
//        } catch {
//            failedToLoadDossiers = true
//            throw error
//        }
//    }
    
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
    /// - Parameter offsets: <#offsets description#>
    /// - Throws: <#description#>
    func deleteDossier(atOffsets offsets: IndexSet) throws {
        try dossiers[offsets.first!].delete()
        dossiers.remove(atOffsets: offsets)
    }
}
