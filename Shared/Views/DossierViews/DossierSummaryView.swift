//
//  DossierSummaryView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Files

struct DossierSummaryView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @State private var alertItem: AlertItem?

    var body: some View {
        if let activeDossier = dataStore.activeDossier {
            Form {
                DossierPropertiesView(dossier: activeDossier,
                                      sectionHeader: "Dossier en cours")
            }
            .navigationTitle(Text("Dossier en cours d'utilisation"))
            .toolbar {
                /// Bouton: Sauvegarder
                ToolbarItem(placement: .automatic) {
                    Button(
                        action : { save(activeDossier) },
                        label  : {
                            HStack {
                                Image(systemName: "externaldrive.fill")
                                    .imageScale(.large)
                                Text("Enregistrer")
                            }
                        })
                        .capsuleButtonStyle()
                        .disabled(!savable())
                }
            }
        } else {
            DossierHomeView()
        }
    }
    
    private func savable() -> Bool {
        family.isModified ||
        patrimoine.isModified
    }

    /// Enregistrer les données utilisateur dans le Dossier sélectionné actif
    private func save(_ dossier: Dossier) {
        // vérifier l'existence du Folder associé au Dossier
        guard let folder = dossier.folder else {
            self.alertItem = AlertItem(title         : Text("Impossible de trouver le Dossier !"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        
        // enregistrer le desscripteur du Dossier
        do {
            try dossier.saveAsJSON()
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de l'enregistrement du dossier"),
                                       dismissButton : .default(Text("OK")))
        }
        // enregistrer les données utilisateur depuis le Dossier
        do {
            try family.saveAsJSON(toFolder: folder)
            try patrimoine.saveAsJSON(toFolder: folder)
            Simulation.playSound()
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de l'enregistrement du contenu du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct DossierSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        DossierSummaryView()
    }
}
