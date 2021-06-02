//
//  ComputationView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import RetirementModel
//import ActivityIndicatorView

struct ComputationView: View {
    @EnvironmentObject var uiState          : UIState
    @EnvironmentObject var dataStore        : Store
    @EnvironmentObject var family           : Family
    @EnvironmentObject var patrimoine       : Patrimoin
    @EnvironmentObject var simulation       : Simulation
    @State private var busySaveWheelAnimate : Bool = false
    //@State private var busyCompWheelAnimate : Bool = false
//    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem            : AlertItem?

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
                        Button(action: saveSimulation,
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
                        //                    .opacity(!savingIsPossible() ? 0.5 : 1.0)
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
    
    func savingIsPossible() -> Bool {
        simulation.isComputed && !simulation.isSaved
    }
    
    func computeSimulation() {
//        busyCompWheelAnimate.toggle()
        // executer les calculs en tâche de fond
//        DispatchQueue.global(qos: .userInitiated).async {
        switch simulation.mode {
            case .deterministic:
                simulation.compute(nbOfYears      : Int(uiState.computationState.nbYears),
                                   nbOfRuns       : 1,
                                   withFamily     : family,
                                   withPatrimoine : patrimoine)
                
            case .random:
                simulation.compute(nbOfYears      : Int(uiState.computationState.nbYears),
                                   nbOfRuns       : Int(uiState.computationState.nbRuns),
                                   withFamily     : family,
                                   withPatrimoine : patrimoine)
        }
//        }
        // mettre à jour les variables d'état dans le thread principal
        //DispatchQueue.main.async {
        uiState.bsChartState.itemSelection = simulation.socialAccounts.balanceArray.getBalanceSheetLegend(.both)
        uiState.cfChartState.itemSelection = simulation.socialAccounts.cashFlowArray.getCashFlowLegend(.both)
        // positionner le curseur de la vue PatrimoinSummaryView sur la bonne date
        uiState.patrimoineViewState.evalDate = simulation.lastYear!.double()
        //}
//        busyCompWheelAnimate.toggle()
        self.alertItem = AlertItem(title         : Text("Les calculs sont terminés. Vous pouvez visualiser les résultats."),
                                   dismissButton : .default(Text("OK")))
//        self.presentationMode.wrappedValue.dismiss()
        #if DEBUG
        // self.simulation.socialAccounts.printBalanceSheetTable()
        #endif
    }
    
    func saveSimulation() {
        // executer l'enregistrement en tâche de fond
        guard let folder = dataStore.activeDossier?.folder else {
            self.alertItem = AlertItem(title         : Text("La sauvegarde a échouée"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        busySaveWheelAnimate.toggle()
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try self.simulation.save(to: folder)
                // mettre à jour les variables d'état dans le thread principal
                DispatchQueue.main.async {
                    self.busySaveWheelAnimate.toggle()
                    self.simulation.isSaved = true
                }
            } catch {
                // mettre à jour les variables d'état dans le thread principal
                DispatchQueue.main.async {
                    self.busySaveWheelAnimate.toggle()
                    self.simulation.isSaved = false
                    self.alertItem = AlertItem(title         : Text("La sauvegarde a échouée"),
                                               dismissButton : .default(Text("OK")))
//                    self.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

struct ComputationView_Previews: PreviewProvider {
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
