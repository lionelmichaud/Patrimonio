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
    
    init() {
        do {
            dossiers = try DossierArray.load()
            failedToLoadDossiers = false
        } catch {
            dossiers = []
            failedToLoadDossiers = true
        }
    }

    /// Charger la liste des Dossiers
    func load() throws {
        do {
            dossiers = try DossierArray.load()
            failedToLoadDossiers = false
        } catch {
            failedToLoadDossiers = true
            throw error
        }
    }

    /// Créer un nouveau Dossier
    /// - Parameters:
    ///   - name: nom du dossier
    ///   - note: note décrivant le dossier
    func createDossier(named name       : String,
                       annotatedBy note : String) throws {
        let newDossier = try Dossier.create(name: name,
                                            note: note)
        dossiers.append(newDossier)
    }

    /// Dupliquer un Dossier
    /// - Parameter dossier: Dossier à duspliquer
    func duplicate(_ dossier: Dossier) throws {
        let newDossier = try dossier.duplicate()
        dossiers.append(newDossier)
    }

    func deleteDossier(atOffsets offsets: IndexSet) throws {
        // supprimer le contenu du dossier et le directory associé
        try dossiers[offsets.first!].delete()
        dossiers.remove(atOffsets: offsets)
    }
}
