//
//  ModelFiscalInheritanceDonationView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalInheritanceDonationView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: InheritanceDonation.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false

    var body: some View {
        Form {
            VersionEditableViewInForm(version: $subModel.version)

            Section(header: Text("Entre Conjoint").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Conjoint",
                                                         grid: $subModel.gridDonationConjoint.transaction(),
                                                         updateDependenciesToModel: updateDependenciesToModel)) {
                    Text("Barême pour Donation entre Conjoint")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation au Conjoint",
                               amount : $subModel.abatConjoint)
            }
            
            Section(header: Text("En Ligne Directe").font(.headline)) {
                NavigationLink(destination: RateGridView(label: "Barême Donation Ligne Directe",
                                                         grid: $subModel.gridLigneDirecte.transaction(),
                                                         updateDependenciesToModel: updateDependenciesToModel)) {
                    Text("Barême pour Donation en Ligne Directe")
                }.isDetailLink(true)
                
                AmountEditView(label  : "Abattement sur Donation/Succession en ligne directe",
                               amount : $subModel.abatLigneDirecte)
            }
            
            AmountEditView(label  : "Abattement sur Succession pour frais Funéraires",
                           amount : $subModel.fraisFunéraires)

            Stepper(value : $subModel.decoteResidence,
                    in    : 0 ... 100.0,
                    step  : 1.0) {
                HStack {
                    Text("Décote sur la Résidence Principale")
                    Spacer()
                    Text("\(subModel.decoteResidence.percentString(digit: 0))")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Succession et Donation")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalInheritanceDonationView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalInheritanceDonationView(updateDependenciesToModel: { },
                                           subModel: .init(source: TestEnvir.model.fiscalModel.inheritanceDonation.model))
            .preferredColorScheme(.dark)
    }
}
