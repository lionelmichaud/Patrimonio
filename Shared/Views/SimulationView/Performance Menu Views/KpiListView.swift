//
//  KpiView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Statistics
import ModelEnvironment
import LifeExpense
import Persistence
import PatrimoineModel
import FamilyModel
import Kpi

struct KpiListView : View {
    @EnvironmentObject var simulation : Simulation
    
    var body: some View {
        ForEach(simulation.kpis.values) { kpi in
            NavigationLink(destination : KpiDetailedView(kpi: kpi,
                                                         simulationMode: simulation.mode)) {
                if let objectiveIsReached = kpi.objectiveIsReached(withMode: simulation.mode) {
                    Image(systemName: objectiveIsReached ? "checkmark.circle.fill" : "multiply.circle.fill")
                        .imageScale(.medium)
                        .foregroundColor(objectiveIsReached ? .green : .red)
                }
                Text(kpi.name)
            }
            .isDetailLink(true)
        }
    }
}

struct KpiDetailedView: View {
    @State var kpi: KPI
    var simulationMode : SimulationModeEnum

    var body: some View {
        VStack {
            Section(header: Text("Mode de Calcul " + simulationMode.displayString).bold()) {
                // afficher le résumé
                KpiSummaryView(kpi            : kpi,
                               simulationMode : simulationMode,
                               withPadding    : true,
                               withDetails    : true)

                // afficher le détail
                if kpi.hasValue(for: simulationMode) {
                    switch simulationMode {
                        case .deterministic:
                            EmptyView()
                            
                        case .random:
                            // simulation de Monté-Carlo
                            HStack {
                                AmountView(label  : "Valeur Moyenne",
                                           amount : kpi.average(withMode : simulationMode) ?? Double.nan,
                                           kEuro  : true)
                                    .padding(.trailing)
                                AmountView(label  : "Valeur Médiane",
                                           amount : kpi.median(withMode : simulationMode) ?? Double.nan,
                                           kEuro  : true)
                                    .padding(.leading)
                            }
                            .padding(.top, 3)
                            HStack {
                                AmountView(label  : "Valeur Minimale",
                                           amount : kpi.min(withMode : simulationMode) ?? Double.nan,
                                           kEuro  : true)
                                    .padding(.trailing)
                                AmountView(label  : "Valeur Maximale",
                                           amount : kpi.max(withMode : simulationMode) ?? Double.nan,
                                           kEuro  : true)
                                    .padding(.leading)
                            }
                            .padding(.top, 3)
                            HistogramView(histogram           : kpi.histogram,
                                          xLimitLine          : kpi.objective,
                                          yLimitLine          : kpi.probaObjective,
                                          xAxisFormatterChoice: .k€)
                    }
                }
            }
        }
        .padding(.horizontal)
        .navigationTitle(kpi.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiDetailedView_Previews: PreviewProvider {
    static func kpiDeterPositif() -> KPI {
        var kpi = KPI(name            : "KPI test",
                      note            : "Note descriptive",
                      objective       : 1000.0,
                      withProbability : 0.5)
        kpi.record(2000.0, withMode: .deterministic)
        return kpi
    }
    static func kpiDeterNegatif() -> KPI {
        var kpi = KPI(name            : "KPI test",
                      note            : "Note descriptive",
                      objective       : 1000.0,
                      withProbability : 0.95)
        kpi.record(200.0, withMode: .deterministic)
        return kpi
    }
    static func kpiRandom() -> KPI {
        var kpi = KPI(name: "KPI test",
                      note: "description",
                      objective: 1000.0,
                      withProbability: 0.95)
        for _ in 0...500 {
            kpi.record(Double.random(in: 0.0 ... 5000.0), withMode: .random)
        }
        kpi.histogram.sort(distributionType : .continuous,
                           openEnds         : false,
                           bucketNb         : 50)
        return kpi
    }
    
    static var previews: some View {
        Group {
            KpiDetailedView(kpi: kpiDeterPositif(),
                            simulationMode: .deterministic)
                .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
                .preferredColorScheme(.dark)
            KpiDetailedView(kpi: kpiDeterNegatif(),
                            simulationMode: .deterministic)
                .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
                .preferredColorScheme(.dark)
            KpiDetailedView(kpi: kpiRandom(),
                            simulationMode: .random)
                .previewDevice("iPad Air (4th generation)")
                .preferredColorScheme(.dark)
        }
    }
}
