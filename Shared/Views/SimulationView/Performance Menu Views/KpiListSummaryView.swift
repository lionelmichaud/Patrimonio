//
//  KpisSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel
import Kpi

struct KpiListSummaryView: View {
    @EnvironmentObject var simulation : Simulation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mode de Calcul " + simulation.mode.displayString)
                .bold()
                .padding()
            Form {
                ForEach(simulation.kpis.values) { kpi in
                    Section(header: Text(kpi.name)) {
                        KpiSummaryView(kpi         : kpi,
                                       withPadding : false,
                                       withDetails : false)
                    }
                }
            }
        }
        .navigationTitle("Synthèse des KPI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiSummaryView: View {
    @EnvironmentObject var simulation : Simulation
    @State var kpi  : KPI
    var withPadding : Bool
    var withDetails : Bool
    
    func kpiNoteSubstituted(_ note: String) -> String {
        var substituted: String = note
        substituted = substituted.replacingOccurrences(of    : "<<OwnershipNature>>",
                                                       with  : UserSettings.shared.ownershipKpiSelection.rawValue,
                                                       count : 1)
        substituted = substituted.replacingOccurrences(of    : "<<AssetEvaluationContext>>",
                                                       with  : UserSettings.shared.assetKpiEvaluatedFraction.rawValue,
                                                       count : 1)
        return substituted
    }
    
    var body: some View {
        if kpi.hasValue(for: simulation.mode) {
            if withDetails {
                Text(kpiNoteSubstituted(kpi.note))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary)
                AmountView(label   : "Valeur Objectif Minimale",
                           amount  : kpi.objective,
                           comment : simulation.mode == .random ? "à atteindre avec une probabilité ≥ \(kpi.probaObjective.percentStringRounded)" : "")
                    .padding(EdgeInsets(top: withPadding ? 3 : 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
                if simulation.mode == .random {
                    HStack {
                        PercentView(label   : "Valeur Objectif Atteinte",
                                    percent : 1.0 - (kpi.probability(for: kpi.objective) ?? Double.nan),
                                    comment : "avec une probabilité de")
                        Image(systemName: kpi.objectiveIsReached(withMode: simulation.mode)! ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
                    }
                    .foregroundColor(kpi.objectiveIsReached(withMode: simulation.mode)! ? .green : .red)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
                }
            }
            HStack {
                AmountView(label   : "Valeur Atteinte",
                           amount  : kpi.value(withMode: simulation.mode)!,
                           comment : simulation.mode == .random ? "avec une probabilité de \(kpi.probaObjective.percentStringRounded)" : "")
                Image(systemName: kpi.objectiveIsReached(withMode: simulation.mode)! ? "checkmark.circle.fill" : "multiply.circle.fill")
                    .imageScale(/*@START_MENU_TOKEN@*/.large/*@END_MENU_TOKEN@*/)
            }
            .foregroundColor(kpi.objectiveIsReached(withMode: simulation.mode)! ? .green : .red)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
            // simulation déterministe
            ProgressBar(value            : kpi.value(withMode: simulation.mode)!,
                        minValue         : 0.0,
                        maxValue         : kpi.objective,
                        backgroundEnabled: false,
                        labelsEnabled    : true,
                        backgroundColor  : .secondary,
                        foregroundColor  : kpi.objectiveIsReached(withMode: simulation.mode)! ? .green : .red,
                        formater: value€Formatter)
            //.padding(.vertical)
            
        } else {
            Text("Valeure indéfinie")
                .foregroundColor(.red)
        }
    }
}

struct KpisSummaryView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var family     = try! Family(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var expenses   = try! LifeExpensesDic(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var patrimoine = try! Patrimoin(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var simulation = Simulation()

    static var previews: some View {
        simulation.compute(using          : model,
                           nbOfYears      : 40,
                           nbOfRuns       : 1,
                           withFamily     : family,
                           withExpenses   : expenses,
                           withPatrimoine : patrimoine)
        return VStack {
            KpiListSummaryView()
        }
        .environmentObject(simulation)
        .previewDevice("iPhone 11")
        .preferredColorScheme(.dark)
    }
}
