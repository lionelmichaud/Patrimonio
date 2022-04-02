//
//  PeriodicInvestDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import AssetsModel
import HelpersView

struct PeriodicInvestDetailedView: View {
    let updateDependenciesToModel : () -> Void
    @Transac var item : PeriodicInvestement

    var body: some View {
        Form {
            LabeledTextField(label: "Nom",
                             defaultText: "obligatoire",
                             text: $item.name)
            LabeledTextEditor(label: "Note", text: $item.note)
            WebsiteEditView(website: $item.website)

            /// propriété
            OwnershipView(ownership  : $item.ownership,
                          totalValue : item.value(atEndOf  : CalendarCst.thisYear))
            
            // acquisition
            Section(header: Text("TYPE")) {
                TypeInvestEditView(investType: $item.type)
                AmountEditView(label: "Versement annuel - net de frais",
                               amount: $item.yearlyPayement)
                AmountEditView(label: "Frais annuels sur versements",
                               amount: $item.yearlyCost)
            }
            
            Section(header: Text("INITIALISATION")) {
                YearPicker(title: "Année de départ (fin d'année)",
                           inRange: CalendarCst.thisYear - 20...CalendarCst.thisYear + 100,
                           selection: $item.firstYear)
                AmountEditView(label: "Valeure initiale",
                               amount: $item.initialValue)
                AmountEditView(label: "Intérêts initiaux",
                               amount: $item.initialInterest)
            }
            
            Section(header: Text("RENTABILITE")) {
                InterestRateTypeEditView(rateType: $item.interestRateType)
                PercentView(label   : "Rendement moyen net d'inflation",
                            percent : item.averageInterestRateNetOfTaxesAndInflation)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("LIQUIDATION")) {
                YearPicker(title: "Année de liquidation (fin d'année)",
                           inRange: item.firstYear...item.firstYear + 100,
                           selection: $item.lastYear)
                AmountView(label: "Valeur liquidative avant prélèvements sociaux et IRPP",
                           amount: liquidatedValue)
                    .foregroundColor(.secondary)
                AmountView(label: "Prélèvements sociaux",
                           amount: socialTaxes)
                    .foregroundColor(.secondary)
                AmountView(label: "Valeure liquidative net de prélèvements sociaux",
                           amount: liquidatedValueAfterSocialTaxes)
                    .foregroundColor(.secondary)
                AmountView(label: "Intérêts cumulés avant prélèvements sociaux",
                           amount: cumulatedInterests)
                    .foregroundColor(.secondary)
                AmountView(label: "Intérêts cumulés après prélèvements sociaux",
                           amount: netCmulatedInterests)
                    .foregroundColor(.secondary)
                AmountView(label: "Intérêts cumulés taxables à l'IRPP",
                           amount: netCmulatedInterests)
                    .foregroundColor(.secondary)
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Invest. Périodique")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }
    
    private var isValid: Bool {
        /// vérifier que le nom n'est pas vide
        guard item.name != "" else {
            return false
        }
        
        /// vérifier que les propriétaires sont correctements définis
        guard item.ownership.isValid else {
            return false
        }
        
        /// vérifier que la clause bénéficiaire est valide
        switch item.type {
            case .lifeInsurance(_, let clause):
                guard clause.isValid else {
                    return false
                }
                
            default: ()
        }
        
        return true
    }
    
    private var liquidatedValue: Double {
        let liquidationDate = self.item.lastYear
        return self.item.value(atEndOf: liquidationDate)
    }
    private var cumulatedInterests: Double {
        let liquidationDate = self.item.lastYear
        return self.item.cumulatedInterestsNetOfInflation(atEndOf: liquidationDate)
    }
    private var netCmulatedInterests: Double {
        let liquidationDate = self.item.lastYear
        return self.item.liquidatedValue(atEndOf: liquidationDate).netInterests
    }
    private var taxableCmulatedInterests: Double {
        let liquidationDate = self.item.lastYear
        return self.item.liquidatedValue(atEndOf: liquidationDate).taxableIrppInterests
    }
    private var socialTaxes: Double {
        let liquidationDate = self.item.lastYear
        return self.item.liquidatedValue(atEndOf: liquidationDate).socialTaxes
    }
    private var liquidatedValueAfterSocialTaxes: Double {
        let liquidationDate = self.item.lastYear
        let liquidatedValue = self.item.liquidatedValue(atEndOf: liquidationDate)
        return liquidatedValue.revenue - liquidatedValue.socialTaxes
    }
}

struct PeriodicInvestDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            PeriodicInvestDetailedView(updateDependenciesToModel: { },
                                       item: .init(source: TestEnvir.patrimoine.assets.periodicInvests.items.first!))
                }
                .previewDisplayName("PeriodicInvestDetailedView")
    }
}
