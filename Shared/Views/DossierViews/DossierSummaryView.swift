//
//  DossierSummaryView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Files
import ModelEnvironment
import LifeExpense
import Persistence
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors
import HelpersView

struct DossierSummaryView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem: AlertItem?

    var body: some View {
        if let activeDossier = dataStore.activeDossier {
            Form {
                DossierPropertiesView(dossier: activeDossier,
                                      sectionHeader: "Dossier en cours")
            }
            .navigationTitle(Text("Dossier en cours d'utilisation"))
            .alert(item: $alertItem, content: newAlert)
            .toolbar {
                /// Bouton: Sauvegarder
                ToolbarItem(placement: .automatic) {
                    DiskButton(text: nil) { save(activeDossier) }
                        .disabled(!savable)
                }
            }
        } else {
            NoLoadedDossierView()
        }
    }
    
    /// True si le dossier a été modifié
    private var savable: Bool {
        family.isModified || expenses.isModified ||
            patrimoine.isModified || model.isModified ||
            simulation.isModified
    }

    // MARK: - Methods

    /// Enregistrer les données utilisateur dans le Dossier sélectionné actif
    private func save(_ dossier: Dossier) {
        do {
            try dossier.saveDossierContentAsJSON { folder in
                try model.saveAsJSON(toFolder: folder)
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
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return DossierSummaryView()
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.uiState)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
    }
}
