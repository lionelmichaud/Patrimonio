//
//  ComputationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import RetirementModel
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
    @State private var busyCompWheelAnimate   : Bool = false
    @State private var alertItem              : AlertItem?
//    @Environment(\.presentationMode) var presentationMode

    struct ComputationForm: View {
        @EnvironmentObject var uiState    : UIState
        @EnvironmentObject var simulation : Simulation

        var parameterSection: some View {
            Section(header: Text("Paramètres de Simulation").font(.headline)) {
                VStack {
                    HStack {
                        Text("Titre")
                            .frame(width: 70, alignment: .leading)
                        TextField("", text: $simulation.title)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    LabeledTextEditor(label: "Note", text: $simulation.note)
                }
                HStack {
                    Text("Nombre d'années à calculer: ") + Text(String(Int(uiState.computationState.nbYears)))
                    Slider(value : $uiState.computationState.nbYears,
                           in    : 5 ... 55,
                           step  : 5,
                           onEditingChanged: {_ in
                           })
                }
                // choix du mode de simulation: cas spécifiques
                // sélecteur: Déterministe / Aléatoire
                CasePicker(pickedCase: $simulation.mode, label: "")
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: simulation.mode) { newMode in
                        Patrimoin.setSimulationMode(to: newMode)
                        Retirement.setSimulationMode(to: newMode)
                        LifeExpense.setSimulationMode(to: newMode)
                    }
                switch simulation.mode {
                    case .deterministic:
                        EmptyView()
                        
                    case .random:
                        HStack {
                            Text("Nombre de run: ") + Text(String(Int(uiState.computationState.nbRuns)))
                            Slider(value : $uiState.computationState.nbRuns,
                                   in    : 100 ... 1000,
                                   step  : 100,
                                   onEditingChanged: {_ in
                                   })
                        }
                }
            }
        }
        
        var resultsSection: some View {
            Section(header: Text("Résultats").font(.headline)) {
                // affichage du statut de la simulation
                if simulation.isComputed {
                    HStack {
                        Text("Simulation disponible: de \(simulation.firstYear!) à \(simulation.lastYear!)")
                            .font(.callout)
                        if simulation.mode == .random {
                            // affichage du nombre de run
                            Spacer(minLength: 100)
                            IntegerView(label   : "Nombre de run exécutés",
                                        integer : simulation.mode == .deterministic ? 1  : simulation.currentRunNb)
                        }
                    }
                    
                } else {
                    // pas de données à afficher
                    VStack(alignment: .leading) {
                        Text("Aucune données à présenter")
                        Text("Calculer une simulation au préalable").foregroundColor(.red)
                    }
                }
            }
        }
        
        var kpiView: some View {
            Group {
                if simulation.isComputed {
                    ForEach(simulation.kpis) { kpi in
                        Section(header: Text(kpi.name)) {
                            if kpi.value(withMode: simulation.mode) != nil {
                                KpiSummaryView(kpi         : kpi,
                                               withPadding : false,
                                               withDetails : false)
                            } else {
                                Text("Valeure indéfinie")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
            }
        }
        
        var body: some View {
            Form {
                // paramétrage de la simulation : cas général
                parameterSection

                // affichage des résultats
                resultsSection
                
                // affichage des valeurs des KPI
                kpiView
            }
        }
    }
    
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
                    
                    // bouton Calculer
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: computeSimulation,
                               label: {
                                HStack(alignment: .center) {
                                    //                                if busyCompWheelAnimate {
                                    //                                    ProgressView()
                                    //                                }
                                    Image(systemName: "function")
                                        .imageScale(.large)
                                    Text("Calculer")
                                }
                               }
                        )
                        .capsuleButtonStyle()
                    }
                }
                .alert(item: $alertItem, content: myAlert)
        } else {
            NoLoadedDossierView()
        }
    }
    
    private func savingIsPossible() -> Bool {
        simulation.isComputed // && !simulation.isSaved
    }
    
    /// Exécuter la simulation
    private func computeSimulation() {
        // busyCompWheelAnimate.toggle()
        // executer les calculs en tâche de fond
        // DispatchQueue.global(qos: .userInitiated).async {
        switch simulation.mode {
            case .deterministic:
                simulation.compute(using          : model,
                                   nbOfYears      : Int(uiState.computationState.nbYears),
                                   nbOfRuns       : 1,
                                   withFamily     : family,
                                   withExpenses   : expenses,
                                   withPatrimoine : patrimoine)
                
            case .random:
                simulation.compute(using          : model,
                                   nbOfYears      : Int(uiState.computationState.nbYears),
                                   nbOfRuns       : Int(uiState.computationState.nbRuns),
                                   withFamily     : family,
                                   withExpenses   : expenses,
                                   withPatrimoine : patrimoine)
        }
        // mettre à jour les variables d'état dans le thread principal
        // DispatchQueue.main.async {
        uiState.bsChartState.itemSelection = simulation.socialAccounts.balanceArray.getBalanceSheetLegend(.both)
        uiState.cfChartState.itemSelection = simulation.socialAccounts.cashFlowArray.getCashFlowLegend(.both)
        // positionner le curseur de la vue PatrimoinSummaryView sur la bonne date
        uiState.patrimoineViewState.evalDate = simulation.lastYear!.double()
        //        busyCompWheelAnimate.toggle()
        self.alertItem = AlertItem(title         : Text("Les calculs sont terminés. Vous pouvez visualiser les résultats."),
                                   dismissButton : .default(Text("OK")))
        // }
        //        } // DispatchQueue.global
        //        self.presentationMode.wrappedValue.dismiss()
        #if DEBUG
        // self.simulation.socialAccounts.printBalanceSheetTable()
        #endif
    }
    
    /// Exporter les résultats de la simulation
    private func exportSimulationResults() {
        let dicoOfCsv = simulation.simulationResultsCSV(using: model)

        // Enregistrer les fichier CSV en tâche de fond dans le dossier `Document` de l'application
        saveSimulationToDocumentsDirectory(dicoOfCSV: dicoOfCsv)
        
        // Paratager les fichiers CSV et Image
        if UserSettings.shared.shareCsvFiles || UserSettings.shared.shareImageFiles {
            shareSimulationResults()
        }
    }
    
    /// Partager les fichiers CSV et Image
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
    
    /// Enregistrer les fichier CSV en tâche de fond dans le dossier `Document` de l'application
    private func saveSimulationToDocumentsDirectory(dicoOfCSV: [String:String]) {
        // folder du dossier actif
        guard let folder = dataStore.activeDossier?.folder else {
            self.alertItem = AlertItem(title         : Text("La sauvegarde locale a échouée"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        busySaveWheelAnimate.toggle()
//        DispatchQueue.global(qos: .userInitiated).async {
            do {
                for (name, csv) in dicoOfCSV {
                    try PersistenceManager.saveToCsvPath(to              : folder,
                                                         fileName        : name,
                                                         simulationTitle : simulation.title,
                                                         csvString       : csv)
                }
                // mettre à jour les variables d'état dans le thread principal
//                DispatchQueue.main.async {
                    self.busySaveWheelAnimate.toggle()
                    self.simulation.isSaved = true
                    Simulation.playSound()
//                } // DispatchQueue
            } catch {
                // mettre à jour les variables d'état dans le thread principal
//                DispatchQueue.main.async {
                    self.busySaveWheelAnimate.toggle()
                    self.simulation.isSaved = false
                    self.alertItem = AlertItem(title         : Text("La sauvegarde locale a échouée"),
                                               dismissButton : .default(Text("OK")))
                    //                    self.presentationMode.wrappedValue.dismiss()
//                } // DispatchQueue
            }
//        } // DispatchQueue
    }
}

struct ComputationView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var dataStore  = Store()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        NavigationView {
            List {
                // calcul de simulation
                NavigationLink(destination : ComputationView()
                                .environmentObject(model)
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("Calculs")
                }
                .isDetailLink(true)
            }
            //.colorScheme(.dark)
            //.padding()
            //.previewLayout(PreviewLayout.sizeThatFits)
        }
    }
}
