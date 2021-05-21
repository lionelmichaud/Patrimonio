//
//  Store.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import Foundation
import os

private let customLog = Logger(subsystem : "me.michaud.lionel.Patrimonio",
                               category  : "Store")

// MARK: - STORE

enum StoreError: String, Error {
    case failedToLoadStore  = "Failed to load Store from the 'Documents' directory"
}

class Store: ObservableObject {
    @Published var dossiers: DossierArray = []

    /// Charger la liste des dossier
    /// - Throws: StoreError.failedToLoadStore
    func load() throws {
        do {
            dossiers = try PersistenceManager.loadUserDossiersFromDocumentsDirectory()
        } catch {
            customLog.log(level: .error,
                          "\(StoreError.failedToLoadStore.rawValue)")
            throw StoreError.failedToLoadStore
        }
    }

    func addDossier(named name       : String,
                    annotatedBy note : String,
                    action           : DossierCreationActionEnum) throws {
        let newDossier: Dossier
        do {
            switch action {
                case .new:
                    newDossier = try Dossier.create(name: name,
                                                    note: note)
                case .copy:
                    newDossier = try Dossier.create(name: name,
                                                    note: note)
            }
        } catch {
            throw error
        }

        dossiers.append(newDossier)
    }

    func deleteDossier(atOffsets offsets: IndexSet) throws {
        // supprimer le contenu du dossier et le directory associé
        do {
            try dossiers[offsets.first!].delete()
        } catch {
            throw error
        }

        // retirer le dossier de la liste
        dossiers.remove(atOffsets: offsets)
    }
}
