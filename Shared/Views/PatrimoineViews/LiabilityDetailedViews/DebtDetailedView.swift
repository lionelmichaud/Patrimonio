//
//  DebtDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Liabilities
import PatrimoineModel
import FamilyModel
import HelpersView
import SimulationAndVisitors

struct DebtDetailedView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState

    // commun
    private var originalItem     : Debt?
    @State private var localItem : Debt
    @State private var alertItem : AlertItem?
    @State private var index     : Int?
    // à adapter

    var body: some View {
        Form {
            LabeledTextField(label: "Nom", defaultText: "obligatoire", text: $localItem.name)
            LabeledTextEditor(label: "Note", text: $localItem.note)

            /// propriété
            OwnershipView(ownership  : $localItem.ownership,
                          totalValue : localItem.value(atEndOf : CalendarCst.thisYear))

            /// acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant emprunté",
                               amount : $localItem.value)
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Dette")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                DuplicateButton { duplicate() }
                    .disabled((index == nil) || changeOccured)
                FolderButton(action : applyChanges)
                    .disabled(!changeOccured)
            }
        }
        .alert(item: $alertItem, content: newAlert)
    }

    init(item       : Debt?,
         family     : Family,
         patrimoine : Patrimoin) {
        self.originalItem       = item
        if let initialItemValue = item {
            // modification d'un élément existant
            _localItem = State(initialValue: initialItemValue)
            _index     = State(initialValue: patrimoine.liabilities.debts.items.firstIndex(of: initialItemValue))
            // specific
        } else {
            // création d'un nouvel élément
            var newItem = Debt(name: "", note: "", value: 0)
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            newItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            _localItem = State(initialValue: newItem)
            index = nil
        }
    }

    private func resetSimulation() {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
    }

    private func duplicate() {
        // générer un nouvel identifiant pour la copie
        localItem.id = UUID()
        localItem.name += "-copie"
        // ajouter un élément à la liste
        patrimoine.liabilities.debts.add(localItem)
        // revenir à l'élement avant duplication
        localItem = originalItem!

        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    // sauvegarder les changements
    private func applyChanges() {
        guard self.isValid else { return }

        if let index = index {
            // modifier un éléménet existant
            patrimoine.liabilities.debts.update(with: localItem, at: index)
        } else {
            // générer un nouvel identifiant pour le nouvel item
            localItem.id = UUID()
            // définir le délégué pour la méthode ageOf qui par défaut est nil à la création de l'objet
            localItem.ownership.setDelegateForAgeOf(delegate: family.ageOf)
            // ajouter le nouvel élément à la liste
            patrimoine.liabilities.debts.add(localItem)
        }
        // remettre à zéro la simulation et sa vue
        resetSimulation()
    }

    private var changeOccured: Bool {
        return localItem != originalItem
    }

    private var isValid: Bool {
        if localItem.value > 0 {
            self.alertItem = AlertItem(title         : Text("Erreur"),
                                       message       : Text("Le montant emprunté doit être négatif"),
                                       dismissButton : .default(Text("OK")))
            return false
        }

        /// vérifier que le nom n'est pas vide
        guard localItem.name != "" else {
            self.alertItem = AlertItem(title         : Text("Donner un nom"),
                                       dismissButton : .default(Text("OK")))
            return false
        }

        /// vérifier que les propriétaires sont correctements définis
        guard localItem.ownership.isValid else {
            self.alertItem = AlertItem(title         : Text("Les propriétaires ne sont pas correctements définis"),
                                       dismissButton : .default(Text("OK")))
            return false
        }

        return true
    }
}

struct DebtDetailedView2: View {
    let updateDependenciesToModel : () -> Void
    @Transac var item : Debt

    var body: some View {
        Form {
            LabeledTextField(label: "Nom",
                             defaultText: "obligatoire",
                             text: $item.name)
            .foregroundColor(item.name.isEmpty ? .red : .primary)
            LabeledTextEditor(label: "Note", text: $item.note)

            /// propriété
            OwnershipView(ownership  : $item.ownership,
                          totalValue : item.value(atEndOf : CalendarCst.thisYear))

            /// acquisition
            Section(header: Text("CARCTERISTIQUES")) {
                AmountEditView(label  : "Montant emprunté",
                               amount : $item.value)
                .foregroundColor(item.value > 0 ? .red : .primary)
                if item.value > 0 {
                    Label("Le montant emprunté doit être négatif", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.red)
                        .padding(.trailing)
                }
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Dette")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }

    private var isValid: Bool {
        /// vérifier que la valeure est négative ou nulle
        guard item.value.isNOZ else {
            return false
        }

        /// vérifier que le nom n'est pas vide
        guard item.name != "" else {
            return false
        }

        /// vérifier que les propriétaires sont correctements définis
        guard item.ownership.isValid else {
            return false
        }

        return true
    }
}

struct DebtDetailedView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoine = Patrimoin()

    static var previews: some View {
        return
            NavigationView {
                DebtDetailedView(item       : patrimoine.liabilities.debts[0],
                                 family     : family,
                                 patrimoine : patrimoine)
                    .environmentObject(family)
                    .environmentObject(patrimoine)
            }
            .previewDisplayName("DebtDetailedView")
    }
}
