//
//  ModelFiscalIsfView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

struct ModelFiscalIsfView: View {
    let updateDependenciesToModel: ( ) -> Void
    @Transac var subModel: IsfModel.Model
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false
    let footnote: String =
        """
        Un système d'abattement progressif a été mis en place pour les patrimoines nets taxables compris entre 1,3 million et 1,4 million d’euros.
        Le montant de la décote est calculé selon la formule 17 500 – (1,25 % x montant du patrimoine net taxable).
        """
    
    var body: some View {
        Form {
            Section {
                VersionEditableViewInForm(version: $subModel.version)
            }
            
            NavigationLink(destination: RateGridView(label: "Barême ISF/IFI",
                                                     grid: $subModel.grid.transaction(),
                                                     updateDependenciesToModel: updateDependenciesToModel)) {
                Text("Barême")
            }.isDetailLink(true)
            
            Section(header: Text("Calcul").font(.headline),
                    footer: Text(footnote)) {
                AmountEditView(label  : "Seuil d'imposition",
                               amount : $subModel.seuil)

                AmountEditView(label  : "Limite supérieure de la tranche de transition",
                               amount : $subModel.seuil2)

                AmountEditView(label  : "Décote maximale",
                               amount : $subModel.decote€)

                Stepper(value : $subModel.decoteCoef,
                        in    : 0 ... 100.0,
                        step  : 0.25) {
                    HStack {
                        Text("Abattement")
                        Spacer()
                        Text("\(subModel.decoteCoef.percentString(digit: 2))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section(header: Text("Décotes Spécifiques").font(.headline)) {
                Stepper(value : $subModel.decoteResidence,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur de la résidence principale")
                        Spacer()
                        Text("\(subModel.decoteResidence.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.decoteLocation,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur d'un bien immobilier en location")
                        Spacer()
                        Text("\(subModel.decoteLocation.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }

                Stepper(value : $subModel.decoteIndivision,
                        in    : 0 ... 100.0,
                        step  : 1.0) {
                    HStack {
                        Text("Décote sur la valeur d'un bien immobilier en indivision")
                        Spacer()
                        Text("\(subModel.decoteIndivision.percentString(digit: 0))")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Imposition sur le Capital")
        .alert(item: $alertItem, content: newAlert)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $subModel,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct ModelFiscalIsfView_Previews: PreviewProvider {
    static var previews: some View {
        ModelFiscalIsfView(updateDependenciesToModel: { },
                           subModel: .init(source: TestEnvir.model.fiscalModel.isf.model))
            .preferredColorScheme(.dark)
    }
}
