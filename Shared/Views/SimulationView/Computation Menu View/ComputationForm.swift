//
//  ComputationForm.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/11/2021.
//

import SwiftUI
import FamilyModel
import ModelEnvironment
import LifeExpense
import PatrimoineModel

struct ComputationForm: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var simulation : Simulation
    @State private var localAlertItem         : AlertItem?
    
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
    
    var kpiValuesView: some View {
        Group {
            if simulation.isComputed {
                ForEach(simulation.kpis.values) { kpi in
                    Section(header: Text(kpi.name)) {
                        if kpi.value(withMode: simulation.mode) != nil {
                            KpiSummaryView(kpi            : kpi,
                                           simulationMode : simulation.mode,
                                           withPadding    : false,
                                           withDetails    : false)
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
            ComputationParametersSectionView()
            
            // bouton pour lancer le calcul de la simulation
            HStack {
                Spacer()
                Button(action: computeSimulation,
                       label: {
                        HStack(alignment: .center) {
                            Image(systemName: "function")
                                .imageScale(.large)
                            Text("Calculer")
                        }
                        .font(.title2)
                        .padding(.vertical, 4.0)
                       }
                )
                .capsuleButtonStyle(width: 200.0)
                .alert(item: $localAlertItem, content: createAlert)
                Spacer()
            }
            
            // affichage des résultats
            resultsSection
            
            // affichage des valeurs des KPI
            kpiValuesView
        }
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
        localAlertItem = AlertItem(title         : Text("Les calculs sont terminés. Vous pouvez visualiser les résultats."),
                                   dismissButton : .default(Text("OK")))
        // }
        //        } // DispatchQueue.global
        //        self.presentationMode.wrappedValue.dismiss()
        #if DEBUG
        // self.simulation.socialAccounts.printBalanceSheetTable()
        #endif
    }
}

struct ComputationForm_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return ComputationForm()
            .environmentObject(modelTest)
            .environmentObject(uiStateTest)
            .environmentObject(dataStoreTest)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(simulationTest)
    }
}
