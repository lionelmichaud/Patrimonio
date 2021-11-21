//
//  KpisParametersEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/11/2021.
//

import SwiftUI
import Persistence
import Kpi

struct KpisParametersEditView: View {
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        List {
            ForEach(simulation.kpis.values) { kpi in
                KpiGroupBox(kpi: kpi)
            }
        }
        .navigationTitle("Critères de performances")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $alertItem, content: createAlert)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                SaveToDiskButton(text: "Modèle", action: applyChangesToTemplate)
                    .disabled(!simulation.isModified)
            }
        }
    }

    /// Enregistrer la modification dans le répertoire Template (sur disque)
    func applyChangesToTemplate() {
        guard let templateFolder = PersistenceManager.templateFolder() else {
            alertItem =
                AlertItem(title         : Text("Répertoire 'Modèle' absent"),
                          dismissButton : .default(Text("OK")))
            return
        }
        do {
            try simulation.saveAsJSON(toFolder: templateFolder)
            // le dossier reste modifié tant qu'on ne l'a pas enregistré dans son propre répertoire
            simulation.persistenceSM.process(event: .onModify)
        } catch {
            alertItem =
                AlertItem(title         : Text("Echec de l'enregistrement"),
                          dismissButton : .default(Text("OK")))
        }
    }
}

struct KpiGroupBox : View {
    @EnvironmentObject private var simulation : Simulation
    @State private var kpi       : KPI
    
    var compareStr: String {
        switch kpi.comparator {
            case .maximize: return " à atteindre"
            case .minimize: return " à ne pas dépasser"
        }
    }
    
    var body: some View {
        GroupBox(label: Text(kpi.name)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.secondary)) {
            VStack {
                HStack {
                    Text(kpiNoteSubstituted(kpi.note))
                        .padding(.top, 8)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                HStack {
                    AmountEditView(label  : "Valeur" + compareStr,
                                   amount : $kpi.objective)
                        .onChange(of: kpi.objective) { value in
                            simulation.kpis[KpiEnum(rawValue: kpi.name)!]?.objective = value
                        }
                    Spacer()
                }
                HStack {
                    PercentEditView(label   : "Avec une probabilité de",
                                    percent : $kpi.probaObjective)
                        .onChange(of: kpi.probaObjective) { value in
                            var kpiCopy = kpi
                            kpiCopy.probaObjective = value / 100.0
                            simulation.setKpi(type  : KpiEnum(rawValue: kpi.name)!,
                                              value : kpiCopy)
                            //simulation.kpis[KpiEnum(rawValue: kpi.name)!]?.probaObjective = value / 100.0
                        }
                    Spacer()
                }
            }
        }
        .groupBoxStyle(DefaultGroupBoxStyle())
    }
    
    internal init(kpi: KPI) {
        var kpiModified = kpi
        kpiModified.probaObjective *= 100.0
        self._kpi  = State(initialValue : kpiModified)
    }
    
    func kpiNoteSubstituted(_ note: String) -> String {
        var substituted: String = note
        substituted = substituted.replacingOccurrences(of    : "<<OwnershipNature>>",
                                                       with  : UserSettings.shared.ownershipGraphicSelection.rawValue,
                                                       count : 1)
        substituted = substituted.replacingOccurrences(of    : "<<AssetEvaluationContext>>",
                                                       with  : UserSettings.shared.assetGraphicEvaluatedFraction.rawValue,
                                                       count : 1)
        return substituted
    }
}

struct KpisParametersEditView_Previews: PreviewProvider {
    static var simulation = Simulation(fromBundle: Bundle.main)
    
    static var previews: some View {
        NavigationView {
            NavigationLink(destination: KpisParametersEditView()
                            .preferredColorScheme(.dark)
                            .environmentObject(simulation)) {
                Text("Critères de performances")
                    .foregroundColor(.accentColor)
            }
        }
    }
}
