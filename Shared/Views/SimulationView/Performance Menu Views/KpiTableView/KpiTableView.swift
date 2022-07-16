//
//  KpiTableView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/06/2022.
//

import SwiftUI
import Persistence
import LifeExpense
import EconomyModel
import SocioEconomyModel
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

    private var adultsName: [String] {
        family.adultsName
    }

    private var selectedLine: SimulationResultLine? {
        guard let selection else { return nil }
        return simulation.monteCarloResultTable.filter { line in
            line.id == selection
        }.first
    }

    var body: some View {
        //        EmptyView()
        Table(simulation.monteCarloResultTable.filtered(with: filter),
              selection: $selection,
              sortOrder: $sortRunOrder) {
            // Colonne Run
            TableColumn("Run", value:\.runNumber) { line in
                Text(String(line.runNumber))
                    .italic()
                    .foregroundColor(colorOfRun(withTheseKpis: line.dicoOfKpiResults))
            }

            //            ForEach(adultsName, id: \.self) { name in
            //            TableColumn("Décès " + family.adults.first!.name.formatted(.abbreviated)) { line in
            TableColumn("Décès ") { line in
                Text(String(line.dicoOfAdultsRandomProperties[adultsName.first!]!.ageOfDeath))
            }
//            TableColumn("DécèsVM") { line in
//                Text(String(line.dicoOfAdultsRandomProperties[adultsName.last!]!.ageOfDeath))
//            }
            //            }

            TableColumn("Inflation") { line in
                Text(line.dicoOfEconomyRandomVariables[Economy.RandomVariable.inflation]?.percentString(digit: 1) ?? "NaN")
            }

            TableColumn("Tx action") { line in
                Text(line.dicoOfEconomyRandomVariables[Economy.RandomVariable.stockRate]?.percentString(digit: 1) ?? "NaN")
            }

            TableColumn("Tx oblig") { line in
                Text(line.dicoOfEconomyRandomVariables[Economy.RandomVariable.securedRate]?.percentString(digit: 1) ?? "NaN")
            }

//            TableColumn("Deval. pension") { line in
//                Text((line.dicoOfSocioEconomyRandomVariables[SocioEconomy.RandomVariable.pensionDevaluationRate]?.percentString(digit: 1) ?? "NaN"))
//            }
        }
              .onChange(of: sortRunOrder) { newOrder in
                  simulation.monteCarloResultTable.sort(using: newOrder)
              }
              .padding(.top)
              .toolbar(content: myToolBarContent)
        //              .navigationTitle("Résultats des Runs de la Simulation")
              .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Methods

    @ToolbarContentBuilder
    func myToolBarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarLeading) {
            // menu de filtrage
            Menu {
                Picker(selection: $filter, label: Text("Filtering options")) {
                    Label("Tous les résultats", systemImage: "checkmark.circle.fill").tag(RunFilterEnum.all)
                    Label("Résultats négatifs", systemImage: "xmark.octagon.fill").tag(RunFilterEnum.someBad)
                    Label("Résultats indéterminés", systemImage: "questionmark.circle").tag(RunFilterEnum.somUnknown)
                }
            } label: {
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

            // rejeu du run sélectionné dans le tableau
            Button {
                replay(thisRun: selectedLine!)
            } label: {
                Label("Rejouer", systemImage: "arrowtriangle.forward.circle")
            }
            .disabled(selection == nil)
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
