//
//  ComputationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Files
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel

struct ComputationView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @State private var busySaveWheelAnimate   : Bool = false
    @State private var alertItem              : AlertItem?

    var body: some View {
        if dataStore.activeDossier != nil {
            ComputationForm()
                .navigationTitle("Calculs")
                // barre de boutons
                .toolbar {
                    // bouton Exporter fichiers CSV
                    ToolbarItem(placement: .automatic) {
                        Button(action: exportSimulationResults,
                               label: {
                                HStack(alignment: .center) {
                                    if busySaveWheelAnimate {
                                        ProgressView()
                                    }
                                    Image(systemName: "square.and.arrow.up")
                                        .imageScale(.large)
                                    Text("Exporter")
                                }
                               }
                        )
                        .capsuleButtonStyle()
                        .shareContextMenu(items: ["Hello world!", "coucou"])
                        .disabled(!savingIsPossible())
                    }
                }
                .alert(item: $alertItem, content: createAlert)
        } else {
            NoLoadedDossierView()
        }
    }
    
    private func savingIsPossible() -> Bool {
        simulation.resultIsValid
    }
    
    /// Exporter les résultats de la simulation
    ///
    /// Enregistrer les fichier CSV en tâche de fond dans le dossier `Document` de l'application
    /// Partager les fichiers CSV et Image existants dans le dossier `Document` de l'application
    ///
    private func exportSimulationResults() {
        busySaveWheelAnimate.toggle()

        let dicoOfCsv = CsvBuilder.simulationResultsCSV(from  : simulation,
                                                        using : model)

        // Enregistrer les fichier CSV en tâche de fond dans le dossier `Document` de l'application
        saveSimulationToDocumentsDirectory(dicoOfCSV: dicoOfCsv)
        
        // Partager les fichiers CSV et Image existants dans le dossier `Document` de l'application
        if UserSettings.shared.shareCsvFiles || UserSettings.shared.shareImageFiles {
            shareSimulationResults()
        }
        
        self.busySaveWheelAnimate.toggle()
        //Simulation.playSound()
    }
    
    /// Enregistrer les fichier CSV en tâche de fond dans le dossier `Document` de l'application
    private func saveSimulationToDocumentsDirectory(dicoOfCSV: [String:String]) {
        // folder du dossier actif
        guard let folder = dataStore.activeDossier?.folder else {
            self.alertItem = AlertItem(title         : Text("La sauvegarde locale a échouée"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        do {
            for (name, csv) in dicoOfCSV {
                try PersistenceManager.saveToCsvPath(to              : folder,
                                                     fileName        : name,
                                                     simulationTitle : simulation.title,
                                                     csvString       : csv)
            }
            // mettre à jour les variables d'état dans le thread principal
            self.simulation.process(event: .onSaveSuccessfulCompletion)
        } catch {
            // mettre à jour les variables d'état dans le thread principal
            self.alertItem = AlertItem(title         : Text("La sauvegarde locale a échouée"),
                                       dismissButton : .default(Text("OK")))
        }
    }

    /// Partager les fichiers CSV et Image existants  dans le dossier `Document` de l'application
    private func shareSimulationResults() {
        guard let folder = dataStore.activeDossier?.folder else {
            self.alertItem = AlertItem(title         : Text("Le partage a échoué"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        // partage des fichiers CSV
        var urls = [URL]()
        if UserSettings.shared.shareCsvFiles {
            do {
                let csvFolder = try PersistenceManager.csvFolder(in                 : folder,
                                                                 forSimulationTitle : simulation.title)
                csvFolder.files.forEach { file in
                    urls.append(file.url)
                }
            } catch {
                self.alertItem = AlertItem(title         : Text("Le partage des fichiers .csv échoué"),
                                           dismissButton : .default(Text("OK")))
            }
        }
        
        // partage des fichiers PNG
        if UserSettings.shared.shareImageFiles {
            let imageFolder = try? PersistenceManager.imageFolder(in                 : folder,
                                                                  forSimulationTitle : simulation.title)
            imageFolder?.files.forEach { file in
                urls.append(file.url)
            }
        }
        
        Patrimonio.share(items: urls)
    }
}
    
struct ComputationView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return NavigationView {
            List {
                // calcul de simulation
                NavigationLink(destination : ComputationView()
                                .environmentObject(modelTest)
                                .environmentObject(uiStateTest)
                                .environmentObject(dataStoreTest)
                                .environmentObject(familyTest)
                                .environmentObject(expensesTest)
                                .environmentObject(patrimoineTest)
                                .environmentObject(simulationTest)
                ) {
                    Text("Calculs")
                }
                .isDetailLink(true)
            }
        }
    }
}
