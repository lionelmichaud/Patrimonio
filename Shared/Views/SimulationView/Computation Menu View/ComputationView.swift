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
import HelpersView

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
    @Preference(\.shareCsvFiles)   var shareCsvFiles
    @Preference(\.shareImageFiles) var shareImageFiles
    @Preference(\.shareAllDossierFilesWithSimuResults) var shareAllDossierFilesWithSimuResults
    @Preference(\.shareFamilyFilesWithSimuResults) var shareFamilyFilesWithSimuResults
    @Preference(\.shareExpensesFilesWithSimuResults) var shareExpensesFilesWithSimuResults
    @Preference(\.sharePatrimoineFilesWithSimuResults) var sharePatrimoineFilesWithSimuResults

    var body: some View {
        if dataStore.activeDossier != nil {
            GeometryReader { geometry in
                ComputationForm()
                    .navigationTitle("Calculs")
                    // barre de boutons
                    .toolbar {
                        // bouton Exporter fichiers CSV
                        ToolbarItem(placement: .automatic) {
                            Button(action: { exportSimulationResults(geometry: geometry) },
                                   label: {
                                    HStack(alignment: .center) {
                                        if busySaveWheelAnimate {
                                            ProgressView()
                                        }
                                        Image(systemName: "square.and.arrow.up.on.square")
                                            .imageScale(.large)
                                        //Text("Exporter")
                                    }
                                   }
                            )
                            .capsuleButtonStyle()
                            .shareContextMenu(items: ["Hello world!", "coucou"])
                            .disabled(!savingIsPossible())
                        }
                    }
                    .alert(item: $alertItem, content: newAlert)
            }
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
    /// Partager les fichiers CSV et Images existantes
    ///
    private func exportSimulationResults(geometry: GeometryProxy) {
        busySaveWheelAnimate.toggle()

        let dicoOfCsv = CsvBuilder.simulationResultsCSV(from  : simulation,
                                                        using : model)

        // Enregistrer les fichier CSV en tâche de fond dans le dossier `Document` de l'application
        saveSimulationToDocumentsDirectory(dicoOfCSV: dicoOfCsv)
        
        // Partager les fichiers CSV et Images existantes
        if shareCsvFiles || shareImageFiles {
            shareSimulationResults(geometry: geometry)
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
            self.simulation.process(event: .onSaveSuccessfulCompletion)
            
        } catch {
            self.alertItem = AlertItem(title         : Text("La sauvegarde locale a échouée"),
                                       dismissButton : .default(Text("OK")))
        }
    }

    /// Partager les fichiers CSV et Images existantes
    private func shareSimulationResults(geometry: GeometryProxy) {
        guard let folder = dataStore.activeDossier?.folder else {
            self.alertItem = AlertItem(title         : Text("Le partage a échoué"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        // collecte des URL des fichiers CSV
        var urls = [URL]()
        if shareCsvFiles {
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
        
        // collecte des URL des fichiers PNG
        if shareImageFiles {
            let imageFolder = try? PersistenceManager.imageFolder(in                 : folder,
                                                                  forSimulationTitle : simulation.title)
            imageFolder?.files.forEach { file in
                urls.append(file.url)
            }
        }
        
        // partager les autres fichiers de contexte
        if shareAllDossierFilesWithSimuResults {
            urls += collectedURLs(dataStore: dataStore,
                                  alertItem: &alertItem)
        } else {
            if shareFamilyFilesWithSimuResults {
                let fileNameKeys = ["person"]
                urls += collectedURLs(dataStore: dataStore,
                                      fileNames: fileNameKeys,
                                      alertItem: &alertItem)
            }
            if shareExpensesFilesWithSimuResults {
                let fileNameKeys = ["LifeExpense"]
                urls += collectedURLs(dataStore: dataStore,
                                      fileNames: fileNameKeys,
                                      alertItem: &alertItem)
            }
            if sharePatrimoineFilesWithSimuResults {
                let fileNameKeys = ["FreeInvestement",
                                    "PeriodicInvestement",
                                    "RealEstateAsset",
                                    "SCPI",
                                    "Debt",
                                    "Loan"]
                urls += collectedURLs(dataStore: dataStore,
                                      fileNames: fileNameKeys,
                                      alertItem: &alertItem)
            }
        }

        // partage des fichiers résultats de simulation collectés
        share(items: urls,
              fromX: Double(geometry.frame(in: .global).maxX-32),
              fromY: 24.0)
        
    }
}
    
struct ComputationView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            List {
                // calcul de simulation
                NavigationLink(destination : ComputationView()
                                .environmentObject(TestEnvir.model)
                                .environmentObject(TestEnvir.uiState)
                                .environmentObject(TestEnvir.dataStore)
                                .environmentObject(TestEnvir.family)
                                .environmentObject(TestEnvir.expenses)
                                .environmentObject(TestEnvir.patrimoine)
                                .environmentObject(TestEnvir.simulation)
                ) {
                    Text("Calculs")
                }
                .isDetailLink(true)
            }
        }
    }
}
