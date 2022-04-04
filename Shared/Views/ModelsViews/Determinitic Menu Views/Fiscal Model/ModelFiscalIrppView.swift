//
//  ModelFiscalIrppView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalIrppView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: IncomeTaxesModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false
    
    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            Section(header: Text("Salaire").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême IRPP",
                                                         grid: $subModel.grid.transaction(),
                                                         updateDependenciesToModel: updateDependenciesToModel)) {
                    Text("Barême")
                }.isDetailLink(true)
                
                Stepper(value : $subModel.salaryRebate,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(subModel.salaryRebate.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }

                AmountEditView(label  : "Abattement minimum",
                               amount : $subModel.minSalaryRebate)

                AmountEditView(label  : "Abattement maximum",
                               amount : $subModel.maxSalaryRebate)

                AmountEditView(label  : "Plafond de Réduction d'Impôt par Enfant",
                               amount : $subModel.childRebate)
            }
            
            Section(header: Text("BNC").font(.headline)) {
                Stepper(value : $subModel.turnOverRebate,
                        in    : 0 ... 100.0) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(subModel.turnOverRebate.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }

                AmountEditView(label  : "Abattement minimum",
                               amount : $subModel.minTurnOverRebate)
            }
        }
        .navigationTitle("Revenus du Travail")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalIrppView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalIrppView(updateDependenciesToModel: { },
                            subModel: .init(source: TestEnvir.model.fiscalModel.incomeTaxes.model))
        .preferredColorScheme(.dark)
    }
}
