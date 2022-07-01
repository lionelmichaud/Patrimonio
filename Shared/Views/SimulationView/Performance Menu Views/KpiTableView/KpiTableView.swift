//
//  KpiTableView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/06/2022.
//

import SwiftUI
import Persistence
import LifeExpense
import ModelEnvironment
import PatrimoineModel
import FamilyModel
import Kpi
import SimulationAndVisitors
import HelpersView

@available(iOS 16.0, *)
struct KpiTableView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @State
    private var sortRunOrder = [KeyPathComparator(\SimulationResultLine.runNumber)]
    @State
    private var selection: SimulationResultLine.ID?
    @State
    private var filter: RunFilterEnum = .all
    @State
    private var showInfoPopover = false
    @State
    private var busySaveWheelAnimate : Bool = false
    @State
    private var alertItem: AlertItem?
    let popOverTitle   = "Contenu du tableau:"
    let popOverMessage =
        """
        Pour chaque run on trouve les paramètre de simulation et
        les indicateurs de performance en résultants.

        Les valeures vertes signifient que l'objectif est atteint.
        Les valeures rouges signifient que l'objectif n'est pas atteint.
        Les ? signifient que l'indicateur de performance n'a pas pu être calculé.
        """

    var body: some View {
        EmptyView()
//        Table(simulation.monteCarloResultTable.filtered(with: filter),
//              selection: $selection,
//              sortOrder: $sortRunOrder) {
//            // Colonne Run
//            TableColumn("Run number", value:\.runNumber) { line in
//                Text(String(line.runNumber))
//                    .italic()
//                    .foregroundColor(colorOfRun(withTheseKpis: line.dicoOfKpiResults))
//                    .frame(
//                        maxWidth: .infinity,
//                        maxHeight: .infinity,
//                        alignment: .leading
//                    )
//                    .contentShape(Rectangle())
//                    .contextMenu {
//                        Button(action: { replay(thisRun: line) }) { 
//                            Label("Rejouer", systemImage: "arrowtriangle.forward.circle")
//                        }
//                    }
//            }
//            TableColumn("Run number", value:\.runNumber) { line in
//                Text(String(line.runNumber))
//                    .italic()
//                    .foregroundColor(colorOfRun(withTheseKpis: line.dicoOfKpiResults))
//            }
//        }
//              .onChange(of: sortRunOrder) { newOrder in
//                  simulation.monteCarloResultTable.sort(using: newOrder)
//              }
//              .padding(.top)
//              .navigationTitle("Résultats des Runs de la Simulation")
//              .navigationBarTitleDisplayMode(.inline)
//              .toolbar(content: myToolBarContent)
    }

    // MARK: - Methods

    @ToolbarContentBuilder
    func myToolBarContent() -> some ToolbarContent {
        // menu de filtrage
        ToolbarItemGroup(placement: .navigationBarLeading) {
            Menu {
                Picker(selection: $filter, label: Text("Filtering options")) {
                    Label("Tous les résultats", systemImage: "checkmark.circle.fill").tag(RunFilterEnum.all)
                    Label("Résultats négatifs", systemImage: "xmark.octagon.fill").tag(RunFilterEnum.someBad)
                    Label("Résultats indéterminés", systemImage: "questionmark.circle").tag(RunFilterEnum.somUnknown)
                }
            }
        label: {
            Image(systemName: "loupe")
                .imageScale(.large)
                .padding(.leading)
        }
            // sauvegarde du tableau
            Button(action: saveGrid ) {
                HStack(alignment: .center) {
                    if busySaveWheelAnimate {
                        ProgressView()
                    }
                    Label("Enregistrer", systemImage: "externaldrive.fill")
                }
            }
            .disabled(dataStore.activeDossier == nil)
        }

        ToolbarItemGroup(placement: .navigationBarTrailing) {
            // afficher info-bulle
            Button(action: { self.showInfoPopover = true },
                   label : {
                Image(systemName: "info.circle")
            })
            .popover(isPresented: $showInfoPopover) {
                PopOverContentView(title       : popOverTitle,
                                   description : popOverMessage)
            }
        }
    }

    func saveGrid() {
        defer {
            // jouer le son à la fin de la sauvegarde
            Simulation.playSound()
        }
        guard let folder = dataStore.activeDossier?.folder else {
            self.alertItem = AlertItem(title         : Text("La sauvegarde a échoué"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        busySaveWheelAnimate.toggle()

        // executer l'enregistrement en tâche de fond
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                /// - un fichier pour le tableau de résultat de Monté-Carlo
                try simulation.monteCarloResultTable.save(to              : folder,
                                                          simulationTitle : simulation.title)
                // mettre à jour les variables d'état dans le thread principal
                DispatchQueue.main.async {
                    self.busySaveWheelAnimate.toggle()
                }
            } catch {
                // mettre à jour les variables d'état dans le thread principal
                DispatchQueue.main.async {
                    self.busySaveWheelAnimate.toggle()
                    self.alertItem = AlertItem(title         : Text((error as? FileError)?.rawValue ?? "La sauvegarde a échoué"),
                                               dismissButton : .default(Text("OK")))
                }
            }
        }
    }

    func replay(thisRun: SimulationResultLine) {
        // rejouer le run unique
        simulation.replay(thisRun        : thisRun,
                          withFamily     : family,
                          withExpenses   : expenses,
                          withPatrimoine : patrimoine,
                          using          : model)
    }

    func colorOfRun(withTheseKpis kpis: KpiResultsDictionary) -> Color {
        let runResult = kpis.runResult()
        switch runResult {
            case .allObjectivesReached:
                return .green
            case .someObjectiveMissed:
                return .red
            case .someObjectiveUndefined:
                return .primary
        }
    }
}

@available(iOS 16.0, *)
struct KpiTableView_Previews: PreviewProvider {
    static var previews: some View {
        KpiTableView()
    }
}
