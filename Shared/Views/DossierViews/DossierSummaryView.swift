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
            .alert(item: $alertItem, content: myAlert)
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
            NoLoadedDossierView()
        }
    }
    
    private func savable() -> Bool {
        family.isModified || patrimoine.isModified
    }

    /// Enregistrer les données utilisateur dans le Dossier sélectionné actif
    private func save(_ dossier: Dossier) {
        do {
            try dossier.saveDossierContentAsJSON { folder in
                try family.saveAsJSON(toFolder: folder)
                try patrimoine.saveAsJSON(toFolder: folder)
                // forcer la vue à se rafraichir
                dataStore.objectWillChange.send()
                Simulation.playSound()
            }
        } catch {
            self.alertItem = AlertItem(title         : Text((error as! DossierError).rawValue),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct DossierSummaryView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        DossierSummaryView()
            .environmentObject(dataStore)
            .environmentObject(uiState)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
