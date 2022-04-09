//
//  KpisParametersEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/11/2021.
//

import SwiftUI
import Persistence
import Kpi
import SimulationAndVisitors
import HelpersView

struct KpisParametersEditView: View {
    @EnvironmentObject private var simulation : Simulation
    @State private var alertItem              : AlertItem?

    var body: some View {
        List {
            ForEach(simulation.kpis.values) { kpi in
                KpiGroupBox(kpi: kpi)
            }
            .alert(item: $alertItem, content: newAlert)
        }
        .navigationTitle("Critères de performances")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                TemplateButton(text   : "Modifier",
                               action : applyChangesToTemplate)
                //.disabled(!simulation.isModified)
            }
        }
    }
    
    /// Enregistrer la modification dans le répertoire Template (sur disque)
    func applyChangesToTemplate() {
        alertItem =
            AlertItem(title         : Text("Modèle"),
                      message       : Text("Voulez-vous appliquer les modifications effectuées au modèle ?"),
                      primaryButton : .default(Text("Appliquer")) {
                        guard let templateFolder = PersistenceManager.templateFolder() else {
                            DispatchQueue.main.async {
                                alertItem =
                                AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                          dismissButton : .default(Text("OK")))
                            }
                            return
                        }
                        do {
                            try simulation.saveAsJSON(toFolder: templateFolder)
                        } catch {
                            DispatchQueue.main.async {
                                alertItem =
                                AlertItem(title         : Text("Echec de l'enregistrement"),
                                          dismissButton : .default(Text("OK")))
                            }
                        }
                      },
                      secondaryButton: .cancel())
    }
}

struct KpiGroupBox : View {
    @EnvironmentObject private var simulation : Simulation
    @State private var kpi : KPI
    @Preference(\.ownershipGraphicSelection) var ownershipGraphicSelection
    @Preference(\.assetGraphicEvaluatedFraction) var assetGraphicEvaluatedFraction

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
                            simulation.setKpi(key   : KpiEnum(rawValue: kpi.name)!,
                                              value : kpi)
                            //simulation.kpis[KpiEnum(rawValue: kpi.name)!]?.objective = value
                            // le dossier reste modifié tant qu'on ne l'a pas enregistré dans son propre répertoire
                            //simulation.persistenceSM.process(event: .onModify)
                        }
                    Spacer()
                }
                HStack {
                    PercentNormEditView(label   : "Avec une probabilité ≥ à",
                                        percent : $kpi.probaObjective)
                        .onChange(of: kpi.probaObjective) { value in
                            simulation.setKpi(key   : KpiEnum(rawValue: kpi.name)!,
                                              value : kpi)
                            // le dossier reste modifié tant qu'on ne l'a pas enregistré dans son propre répertoire
                            //simulation.persistenceSM.process(event: .onModify)
                        }
                    Spacer()
                }
            }
        }
                    .groupBoxStyle(.automatic)
    }
    
    internal init(kpi: KPI) {
        self._kpi  = State(initialValue : kpi)
    }
    
    private func kpiNoteSubstituted(_ note: String) -> String {
        var substituted: String = note
        substituted = substituted.replacingOccurrences(of    : "<<OwnershipNature>>",
                                                       with  : ownershipGraphicSelection.rawValue,
                                                       count : 1)
        substituted = substituted.replacingOccurrences(of    : "<<AssetEvaluationContext>>",
                                                       with  : assetGraphicEvaluatedFraction.rawValue,
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
