//
//  KpisSummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Statistics
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel
import Kpi
import HelpersView

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
                        KpiSummaryView(kpi            : kpi,
                                       simulationMode : simulation.mode,
                                       withPadding    : false,
                                       withDetails    : false)
                    }
                }
            }
        }
        .navigationTitle("Synthèse des KPI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct KpiSummaryView: View {
    @State var kpi     : KPI
    @Preference(\.ownershipGraphicSelection)     var ownershipGraphicSelection
    @Preference(\.assetGraphicEvaluatedFraction) var assetGraphicEvaluatedFraction
    var simulationMode : SimulationModeEnum
    var withPadding    : Bool
    var withDetails    : Bool
    var maxiMiniStr : String {
        switch kpi.comparator {
            case .maximize:
                return "Minimale"
            case .minimize:
                return "Maximale"
        }
    }
    var compareStr : String {
        switch kpi.comparator {
            case .maximize:
                return "à dépasser"
            case .minimize:
                return "à ne pas dépasser"
        }
    }

    func kpiNoteSubstituted(_ note: String) -> String {
        var substituted: String = note
        substituted = substituted.replacingOccurrences(of    : "<<OwnershipNature>>",
                                                       with  : ownershipGraphicSelection.rawValue,
                                                       count : 1)
        substituted = substituted.replacingOccurrences(of    : "<<AssetEvaluationContext>>",
                                                       with  : assetGraphicEvaluatedFraction.rawValue,
                                                       count : 1)
        return substituted
    }
    
    var body: some View {
        if kpi.hasValue(for: simulationMode) {
            if withDetails {
                Text(kpiNoteSubstituted(kpi.note))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary)
                AmountView(label   : "Valeur Objectif " + maxiMiniStr,
                           amount  : kpi.objective,
                           kEuro   : true,
                           comment : simulationMode == .random ? compareStr + " avec une probabilité ≥ \(kpi.probaObjective.percentStringRounded)" : "")
                    .padding(EdgeInsets(top: withPadding ? 3 : 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
                if simulationMode == .random {
                    HStack {
                        PercentNormView(label : "Critère satisfait",
                                    percent   : kpi.probability(for  : kpi.objective) ?? Double.nan,
                                    comment   : "avec une probabilité de")
                        Image(systemName: kpi.objectiveIsReached(withMode: simulationMode)! ? "checkmark.circle.fill" : "multiply.circle.fill")
                            .imageScale(.large)
                    }
                    .foregroundColor(kpi.objectiveIsReached(withMode: simulationMode)! ? .green : .red)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
                }
            }
            HStack {
                AmountView(label   : "Valeur " + maxiMiniStr + " Atteinte",
                           amount  : kpi.value(withMode: simulationMode)!,
                           kEuro   : true,
                           comment : simulationMode == .random ? "avec une probabilité de \(kpi.probaObjective.percentStringRounded)" : "")
                Image(systemName: kpi.objectiveIsReached(withMode: simulationMode)! ? "checkmark.circle.fill" : "multiply.circle.fill")
                    .imageScale(.large)
            }
            .foregroundColor(kpi.objectiveIsReached(withMode: simulationMode)! ? .green : .red)
            .padding(EdgeInsets(top: 0, leading: 0, bottom: withPadding ? 3 : 0, trailing: 0))
            // simulation déterministe
            if (kpi.comparator == .maximize && kpi.value(withMode: simulationMode)! >= kpi.objective) ||
                (kpi.comparator == .minimize && kpi.value(withMode: simulationMode)! <= kpi.objective) {
                // Succès
                ProgressBar(value             : kpi.objective,
                            minValue          : 0.0,
                            maxValue          : kpi.value(withMode: simulationMode)!,
                            backgroundEnabled : true,
                            externalLabels    : true,
                            internalLabels    : true,
                            backgroundColor   : kpi.objectiveIsReached(withMode: simulationMode)! ? .green : .red,
                            foregroundColor   : .gray,
                            maxValuePercent      : true,
                            formater          : valueKilo€Formatter)
            } else {
                // Echec
                ProgressBar(value             : kpi.value(withMode: simulationMode)!,
                            minValue          : 0.0,
                            maxValue          : kpi.objective,
                            backgroundEnabled : true,
                            externalLabels    : true,
                            internalLabels    : true,
                            backgroundColor   : .secondary,
                            foregroundColor   : kpi.objectiveIsReached(withMode: simulationMode)! ? .green : .red,
                            valuePercent      : true,
                            formater          : valueKilo€Formatter)
            }
            //.padding(.vertical)
            
        } else {
            Text("Valeure indéfinie")
                .foregroundColor(.red)
        }
    }
}

struct KpisSummaryView_Previews: PreviewProvider {
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
            VStack {
                KpiSummaryView(kpi            : kpiDeterPositif(),
                               simulationMode : .deterministic,
                               withPadding    : true,
                               withDetails    : true)
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
            
            VStack {
                KpiSummaryView(kpi            : kpiRandom(),
                               simulationMode : .random,
                               withPadding    : true,
                               withDetails    : true)
            }
            .previewLayout(.fixed(width: 700, height: 200.0))
            .preferredColorScheme(.dark)

            VStack {
                KpiSummaryView(kpi            : kpiDeterPositif(),
                               simulationMode : .deterministic,
                               withPadding    : false,
                               withDetails    : false)
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700, height: /*@START_MENU_TOKEN@*/200.0/*@END_MENU_TOKEN@*/))
            
            VStack {
                KpiSummaryView(kpi            : kpiRandom(),
                               simulationMode : .random,
                               withPadding    : false,
                               withDetails    : false)
            }
            .previewLayout(.fixed(width: 700, height: 200.0))
            .preferredColorScheme(.dark)
        }
    }
}
