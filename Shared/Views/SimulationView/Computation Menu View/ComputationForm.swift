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
import SimulationAndVisitors
import HelpersView

struct ComputationForm: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        VStack(alignment: .leading) {
            // paramétrage de la simulation : cas général
            ComputationParametersSectionView()

            // bouton pour lancer le calcul de la simulation
            HStack {
                Spacer()
                // Choix des paramètres des KPIs
                EditKpisButtonView()
                Spacer()
                ComputationButonView()
                Spacer()
            }
                .padding(.top)

            Form {
                // affichage des résultats
                resultsSectionView
                
                // affichage des valeurs des KPI
                kpiValuesView
            }
        }
    }
    
    var resultsSectionView: some View {
        Section {
            // affichage du statut de la simulation
            if simulation.isComputed {
                HStack {
                    Text("Simulation disponible:\nde \(simulation.firstYear!) à \(simulation.lastYear!)")
                        .font(.callout)
                    if simulation.mode == .random {
                        // affichage du nombre de run
                        Spacer()
                        Text("Nombre de run exécutés:\n\(simulation.mode == .deterministic ? 1  : simulation.currentRunNb)")
                    }
                    Spacer()
                    if let result = simulation.kpis.allObjectivesAreReached(withMode: simulation.mode) {
                        if result {
                            Text("Tous les critères de performance sont satisfaits")
                                .foregroundColor(.green)
                        } else {
                            Text("Certains critères de performance ne sont pas satisfaits")
                                .foregroundColor(.red)
                        }
                    }
                }
                
            } else {
                // pas de données à afficher
                VStack(alignment: .leading) {
                    Text("Aucune données à présenter")
                    Text("Calculer une simulation au préalable").foregroundColor(.red)
                }
            }
        } header: {
            Text("Résultats").font(.headline)
        }
    }
    
    var kpiValuesView: some View {
        Group {
            if simulation.isComputed {
                ForEach(simulation.kpis.values) { kpi in
                    Section {
                        if kpi.value(withMode: simulation.mode) != nil {
                            KpiSummaryView(kpi            : kpi,
                                           simulationMode : simulation.mode,
                                           withPadding    : false,
                                           withDetails    : false)
                        } else {
                            Text("Valeure indéfinie")
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text(kpi.name)
                    }
                }
            }
        }
    }
}

struct ComputationButonView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    @State private var localAlertItem         : AlertItem?

    var body: some View {
        Button(
            action: computeSimulation,
            label: {
                Label("Calculer", systemImage: "function")
                    .font(.title2)
                    .padding(.vertical, 4.0)
            })
        .buttonStyle(.borderedProminent)
        //.capsuleButtonStyle(width: 200.0)
        .alert(item: $localAlertItem, content: newAlert)
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

struct EditKpisButtonView: View {
    @State private var showKpiEditView: Bool = false

    var body: some View {
        HStack {
            Button(
                action: { showKpiEditView = true },
                label : {
                    Label("Critères de performances", systemImage: "thermometer")
                        .font(.title2)
                        .padding(.vertical, 4.0)
                })
            .buttonStyle(.borderedProminent)

            //.buttonStyle(.bordered)
            NavigationLink(destination: KpisParametersEditView(), isActive: $showKpiEditView) {
                EmptyView()
            }
        }
    }
}

struct ComputationForm_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ComputationForm()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
            .environmentObject(TestEnvir.uiState)
    }
}
