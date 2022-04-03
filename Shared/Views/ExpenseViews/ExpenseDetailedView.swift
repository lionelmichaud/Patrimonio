//
//  ExpenseDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import LifeExpense
import PatrimoineModel
import SimulationAndVisitors
import HelpersView

// MARK: - View Model for LifeExpense

final class LifeExpenseViewModel: ObservableObject {
    
    // MARK: - Properties
    
    @Published var name         : String = ""
    @Published var note         : String = ""
    @Published var value        : Double = 0.0
    @Published var proportional : Bool   = false
    @Published var timeSpanVM   : TimeSpanViewModel
    
    // MARK: - Computed properties
    
    // construire l'objet de type LifeExpense correspondant au ViewModel
    var lifeExpense: LifeExpense {
        return LifeExpense(name         : self.name,
                           note         : self.note,
                           timeSpan     : self.timeSpanVM.timeSpan,
                           proportional : self.proportional,
                           value        : self.value)
    }
    
    // MARK: - Initializers of ViewModel from Model

    internal init(from expense: LifeExpense) {
        self.name         = expense.name
        self.note         = expense.note
        self.value        = expense.value
        self.proportional = expense.proportional
        self.timeSpanVM   = TimeSpanViewModel(from: expense.timeSpan)
    }
    
    internal init() {
        self.timeSpanVM   = TimeSpanViewModel()
    }

    // MARK: - Methods
    
    func differs(from thisLifeExpense: LifeExpense) -> Bool {
        return
            self.name         != thisLifeExpense.name ||
            self.note         != thisLifeExpense.note ||
            self.value        != thisLifeExpense.value ||
            self.proportional != thisLifeExpense.proportional ||
            self.timeSpanVM   != TimeSpanViewModel(from: thisLifeExpense.timeSpan)
    }
}
    
// MARK: - View

struct ExpenseDetailedView: View {
    let updateDependenciesToModel : () -> Void
    let category      : LifeExpenseCategory
    @Transac var item : LifeExpense

    // MARK: - Computed Properties
    
    var body: some View {
        Form {
            /// nom
            LabeledTextField(label       : "Nom",
                             defaultText : "obligatoire",
                             text        : $item.name,
                             validity    : .notEmpty)
            LabeledTextEditor(label: "Note", text: $item.note)

            /// montant de la dépense
            AmountEditView(label    : "Montant annuel",
                           amount   : $item.value,
                           validity : .poz)
            
            /// proportionnalité de la dépense aux nb de membres de la famille
            Toggle("Proportionnel au nombre de membres à charge de la famille",
                   isOn: $item.proportional)
            
            /// plage de temps
            TimeSpanEditView(timeSpan: $item.timeSpan)
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle(Text("Catégorie: " + category.displayString))
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : item.isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ExpenseDetailedView_Previews: PreviewProvider {
    static func notifyComputationInputsModification() {
        print("simluation.reset")
    }

    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            ExpenseDetailedView(updateDependenciesToModel: notifyComputationInputsModification,
                                category : .autres,
                                item: .init(source: TestEnvir.expenses[.autres]!.items.first!))
            EmptyView()
        }
        .previewDisplayName("ExpenseDetailedView")
    }
}
