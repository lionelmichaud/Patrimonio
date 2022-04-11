//
//  SCPIDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import AssetsModel
import HelpersView

struct ScpiDetailedView: View {
    @EnvironmentObject var model  : Model
    let updateDependenciesToModel : () -> Void
    @Transac var item : SCPI
    @State private var showingBuySheet = false

    var body: some View {
        Form {
            LabeledTextField(label       : "Nom",
                             defaultText : "obligatoire",
                             text        : $item.name,
                             validity    : .notEmpty)
            LabeledTextEditor(label: "Note", text: $item.note)
            WebsiteEditView(website: $item.website)

            /// Acquisition
            Section {
                DatePicker(selection: $item.buyingDate,
                           displayedComponents: .date,
                           label: { Text("Date d'acquisition") })
                AmountEditView(label    : "Prix d'acquisition",
                               amount   : $item.buyingPrice,
                               validity : .poz)
                /// Bouton: Acheter des SCPI
                Button(
                    action : {
                        withAnimation {
                            self.showingBuySheet = true
                        }
                    },
                    label  : {
                        Label(title: { Text("Acheter des parts") },
                              icon : {
                            Image(systemName : "plus.circle.fill")
                            .imageScale(.large) })
                    })
            } header: {
                Text("ACQUISITION")
            }
            .sheet(isPresented: $showingBuySheet) {
                BuyScpiSheet(scpi: $item)
            }

            /// Propriété
            OwnershipView(ownership  : $item.ownership,
                          totalValue : item.value(atEndOf : CalendarCst.thisYear))
            
            /// Rendement
            Section {
                PercentEditView(label    : "Taux de rendement annuel brut",
                                percent  : $item.interestRate)
                AmountView(label: "Revenu annuel brut déflaté (avant prélèvements sociaux et IRPP)",
                           amount: item.yearlyRevenueIRPP(during: CalendarCst.thisYear).revenue)
                .foregroundColor(.secondary)
                AmountView(label: "Charges sociales (si imposable à l'IRPP)",
                           amount: item.yearlyRevenueIRPP(during: CalendarCst.thisYear).socialTaxes)
                .foregroundColor(.secondary)
                AmountView(label: "Revenu annuel déflaté net de charges sociales (imposable à l'IRPP)",
                           amount: item.yearlyRevenueIRPP(during: CalendarCst.thisYear).taxableIrpp)
                .foregroundColor(.secondary)
                AmountView(label: "Revenu annuel déflaté net d'IS (si imposable à l'IS)",
                           amount: model.fiscalModel.companyProfitTaxes.net(item.yearlyRevenueIRPP(during: CalendarCst.thisYear).revenue))
                .foregroundColor(.secondary)
                PercentEditView(label    : "Taux de réévaluation annuel",
                                percent  : $item.revaluatRate)
            } header: {
                Text("RENDEMENT")
            }
            
            /// Vente
            Section {
                Toggle("Sera vendue", isOn: $item.willBeSold)
                if item.willBeSold {
                    Group {
                        DatePicker(selection: $item.sellingDate,
                                   in: item.buyingDate...100.years.fromNow!,
                                   displayedComponents: .date,
                                   label: {
                            Text("Date de vente")
                                .foregroundColor(item.buyingDate > item.sellingDate ? .red : .primary)
                        })
                        AmountView(label: "Valeur à la date de vente (net de commission de vente)",
                                   amount: item.value(atEndOf: item.sellingDate.year))
                        .foregroundColor(.secondary)
                        AmountView(label: "Produit net de commission, de charges sociales et d'IRPP sur les plus-value (régime IRPP)",
                                   amount: item.liquidatedValueIRPP(item.sellingDate.year).netRevenue)
                        .foregroundColor(.secondary)
                        AmountView(label: "Produit net de commission et d'IS sur les plus-value (régime IS)",
                                   amount: item.liquidatedValueIS(item.sellingDate.year).netRevenue)
                        .foregroundColor(.secondary)
                    }
                    .padding(.leading)
                }
            } header: {
                Text("VENTE")
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("SCPI")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : item.isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct SCPIDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            ScpiDetailedView(updateDependenciesToModel: { },
                             item: .init(source: TestEnvir.patrimoine.assets.scpis.items.first!))
            .environmentObject(TestEnvir.model)
        }
        .previewDisplayName("SCPIDetailedView")
    }
}
