//
//  FamilySummaryView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 31/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import Persistence

struct FamilySummaryView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @State private var cashFlow : CashFlowLine?
    
    fileprivate func computeCurrentYearCashFlow() {
        // sauvegarder l'état initial du patrimoine pour y revenir à la fin de chaque run
        patrimoine.saveState()
        //simulation.reset(withPatrimoine: patrimoine)
        self.cashFlow = try? CashFlowLine(run           : 0,
                                          withYear      : Date.now.year,
                                          withFamily    : self.family,
                                          withPatrimoine: self.patrimoine,
                                          taxableIrppRevenueDelayedFromLastyear : 0,
                                          using         : model)
        patrimoine.restoreState()
    }
    
    var body: some View {
        if dataStore.activeDossier != nil {
            Form {
                FamilySummarySection()
                RevenuSummarySection(cashFlow: cashFlow)
                FiscalSummarySection(cashFlow: cashFlow)
                SciSummarySection(cashFlow: cashFlow)
            }
            .navigationTitle("Résumé")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: computeCurrentYearCashFlow)
            .onDisappear(perform: self.patrimoine.resetFreeInvestementCurrentValue)
        } else {
            NoLoadedDossierView()
        }
    }
}

private func header(_ trailingString: String) -> some View {
    HStack {
        Text(trailingString)
        Spacer()
        Text("valorisation en \(Date.now.year)")
    }
}

struct FamilySummarySection: View {
    @EnvironmentObject var family: Family
    var body: some View {
        Section(header: Text("MEMBRES")) {
            IntegerView(label   : "Nombre de membres",
                        integer : family.members.items.count)
            IntegerView(label   : "• Nombre d'adultes",
                        integer : family.nbOfAdults)
            IntegerView(label   : "• Nombre d'enfants",
                        integer : family.nbOfBornChildren)
        }
    }
}

struct RevenuSummarySection: View {
    var cashFlow : CashFlowLine?
    @EnvironmentObject var model : Model
    @EnvironmentObject var family: Family
    
    var body: some View {
        if cashFlow == nil {
            Section(header: header("REVENUS DU TRAVAIL")) {
                AmountView(label : "Revenu net de charges sociales et d'assurance (à vivre)",
                           amount: family.income(during: Date.now.year, using: model).netIncome)
                AmountView(label : "Revenu imposable à l'IRPP",
                           amount: family.income(during: Date.now.year, using: model).taxableIncome)
            }
        } else {
            Section(header: header("REVENUS")) {
                AmountView(label : "Revenu familliale net de charges sociales et d'assurance (à vivre)",
                           amount: cashFlow!.adultsRevenues.totalRevenue)
                AmountView(label : "Revenu de la SCI net de taxes et d'IS ",
                           amount: cashFlow!.sciCashFlowLine.netRevenues)
                AmountView(label : "Revenu total net",
                           amount: cashFlow!.sumOfRevenues,
                           weight: .bold)
                AmountView(label : "Revenu imposable à l'IRPP",
                           amount: cashFlow!.adultsRevenues.totalTaxableIrpp)
            }
        }
    }
}

struct FiscalSummarySection: View {
    var cashFlow : CashFlowLine?
    @EnvironmentObject var model : Model
    @EnvironmentObject var family: Family

    var body: some View {
        if cashFlow == nil {
            Section(header: header("FISCALITE DES REVENUS DU TRAVAIL")) {
                AmountView(label : "Montant de l'IRPP",
                           amount: family.irpp(for: Date.now.year, using: model))
                IntegerView(label   : "Quotient familial",
                            integer : Int(family.familyQuotient(during: Date.now.year, using: model)))
                    .padding(.leading)
            }
        } else {
            Section(header: header("FISCALITE FAMILLE")) {
                AmountView(label : "Montant de l'IRPP",
                           amount: cashFlow!.adultTaxes.perCategory[.irpp]!.total)
                IntegerView(label   : "Quotient familial",
                            integer : Int(cashFlow!.adultTaxes.irpp.familyQuotient))
                    .foregroundColor(.secondary)
                    .padding(.leading)
                PercentView(label   : "Taux moyen d'imposition",
                            percent : cashFlow!.adultTaxes.irpp.averageRate)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                AmountView(label : "Montant de l'ISF",
                           amount: cashFlow!.adultTaxes.perCategory[.isf]!.total)
                AmountView(label  : "Assiette ISF",
                           amount : cashFlow!.adultTaxes.isf.taxable)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                PercentView(label   : "Taux ISF",
                            percent : cashFlow!.adultTaxes.isf.marginalRate)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                AmountView(label : "Taxes locales",
                           amount: cashFlow!.adultTaxes.perCategory[.localTaxes]!.total)
                AmountView(label : "Prélevements Sociaux",
                           amount: cashFlow!.adultTaxes.perCategory[.socialTaxes]!.total)
                AmountView(label : "Prélevements totaux",
                           amount: cashFlow!.adultTaxes.total,
                           weight: .bold)
            }
        }
    }
}

struct SciSummarySection: View {
    var cashFlow : CashFlowLine?
    
    var body: some View {
        Section(header: header("FISCALITE SCI")) {
            AmountView(label : "Montant de l'IS de la SCI",
                       amount: cashFlow!.sciCashFlowLine.IS)
        }
    }
}

struct FamilySummaryView_Previews: PreviewProvider {
    static let dataStore  = Store()
    static var model      = Model(fromBundle: Bundle.main)
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()
    
    static var previews: some View {
        FamilySummaryView()
            .environmentObject(dataStore)
            .environmentObject(model)
            .environmentObject(family)
            .environmentObject(patrimoine)
            .environmentObject(simulation)
    }
}
