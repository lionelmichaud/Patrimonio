//
//  MainActivityRevenuView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 10/07/2022.
//

import SwiftUI
import HelpersView
import PersonModel
import FiscalModel
import ModelEnvironment
import FamilyModel

struct ActivityViewModel {
    var income : WorkIncomeType?
    var revenueBrut    = 0.0
    var revenueNet     = 0.0
    var revenueTaxable = 0.0
    var revenueLiving  = 0.0
    var fromDate       = ""
    var toDate         = ""
    var insurance      = 0.0

    // MARK: - Initializers

    init() {
    }

    init(from adult: Adult, using model: Model) {
        income = adult.workIncome
        switch income {
            case let .salary(_, _, _, fromDate1, healthInsurance):
                revenueBrut    = adult.workBrutIncome
                revenueTaxable = adult.workTaxableIncome(using: model)
                revenueLiving  = adult.workLivingIncome(using: model)
                revenueNet     = adult.workNetIncome(using: model)
                fromDate       = fromDate1.stringMediumDate
                insurance      = healthInsurance

            case let .turnOver(_, incomeLossInsurance):
                revenueBrut    = adult.workBrutIncome
                revenueTaxable = adult.workTaxableIncome(using: model)
                revenueLiving  = adult.workLivingIncome(using: model)
                revenueNet     = adult.workNetIncome(using: model)
                insurance      = incomeLossInsurance

            case .none: // nil
                revenueBrut    = 0
                revenueTaxable = 0
                revenueLiving  = 0
                revenueNet     = 0
                insurance      = 0
        }
    }

    init(from sideWork: SideWork, using fiscalModel: Fiscal.Model) {
        let workIncomeManager = WorkIncomeManager()
        income   = sideWork.workIncome
        fromDate = sideWork.startDate.stringMediumDate
        toDate   = sideWork.endDate.stringMediumDate
        switch income {
            case let .salary(_, _, _, _, healthInsurance):
                revenueBrut    = workIncomeManager.workBrutIncome(from: sideWork)
                revenueTaxable = workIncomeManager.workTaxableIncome(from: sideWork, using: fiscalModel)
                revenueLiving  = workIncomeManager.workLivingIncome(from: sideWork, using: fiscalModel)
                revenueNet     = workIncomeManager.workNetIncome(from: sideWork, using: fiscalModel)
                insurance      = healthInsurance

            case let .turnOver(_, incomeLossInsurance):
                revenueBrut    = workIncomeManager.workBrutIncome(from: sideWork)
                revenueTaxable = workIncomeManager.workTaxableIncome(from: sideWork, using: fiscalModel)
                revenueLiving  = workIncomeManager.workLivingIncome(from: sideWork, using: fiscalModel)
                revenueNet     = workIncomeManager.workNetIncome(from: sideWork, using: fiscalModel)
                insurance      = incomeLossInsurance

            case .none: // nil
                revenueBrut    = 0
                revenueTaxable = 0
                revenueLiving  = 0
                revenueNet     = 0
                insurance      = 0
        }
    }
}

struct WorkRevenuView: View {
    var adult : Adult
    @EnvironmentObject private var model: Model

    // MARK: - Properties

    @State var viewModel = ActivityViewModel()

    var body: some View {
        Form {
            Section {
                ActivityRevenueView(viewModel: viewModel)
            } header: {
                HStack {
                    Text("ACTIVITÉ PRINCIPALE")
                    Spacer()
                    Text(viewModel.revenueLiving.€String)
                }.font(.subheadline)
            }

            if let sideWorks = adult.sideWorks {
                Section {
                    List(sideWorks) { sideWork in
                        SideworkRevenueView(sideWork: sideWork)
                    }
                } header: {
                    Text("ACTIVITÉS ANNEXES").font(.subheadline)
                }
            }
        }
        .navigationTitle("Revenus d'activités de \(adult.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
    }

    // MARK: - Methods

    func onAppear() {
        viewModel = ActivityViewModel(from: adult, using: model)
    }
}

struct SideworkRevenueView : View {
    var sideWork: SideWork
    @EnvironmentObject private var model: Model

    // MARK: - Properties

    @State var viewModel = ActivityViewModel()

    var body: some View {
        DisclosureGroup {
            ActivityRevenueView(viewModel: viewModel)
                .onAppear(perform: onAppear)
        } label: {
            HStack {
                Text(sideWork.name)
                Spacer()
                Text(viewModel.revenueLiving.€String)
            }
            .textCase(.uppercase)
            .font(.headline)
        }
    }

    // MARK: - Methods

    func onAppear() {
        viewModel = ActivityViewModel(from: sideWork, using: model.fiscalModel)
    }
}

struct ActivityRevenueView : View {
    let viewModel : ActivityViewModel

    var body: some View {
        if viewModel.income?.pickerString == "Salaire" {
            HStack {
                Text("Date de début de contrat")
                Spacer()
                Text(viewModel.fromDate)
            }
            if viewModel.toDate != "" {
                HStack {
                    Text("Date de fin de contrat")
                    Spacer()
                    Text(viewModel.toDate)
                }
            }
            AmountView(label : "Salaire brut annuel", amount : viewModel.revenueBrut)
            AmountView(label : "Prélèvements sociaux", amount : viewModel.revenueBrut - viewModel.revenueNet)
            AmountView(label : "Salaire net de feuille de paye", amount : viewModel.revenueNet)
            AmountView(label : "Coût de la mutuelle (protec. sup.)", amount : viewModel.insurance)
            AmountView(label : "Salaire net moins mutuelle facultative (à vivre)", amount : viewModel.revenueLiving, weight: .bold)
            AmountView(label : "Salaire imposable (après abattement)", amount : viewModel.revenueTaxable)
        } else {
            AmountView(label : "BNC", amount : viewModel.revenueBrut)
            AmountView(label : "Prélèvements sociaux", amount : viewModel.revenueBrut - viewModel.revenueNet)
            AmountView(label : "BNC net de prélèvements sociaux", amount : viewModel.revenueNet)
            AmountView(label : "Charges (assurance, frais bancaires, services, CFE)", amount : viewModel.insurance)
            AmountView(label : "BNC net de prélèvements sociaux et de charges (à vivre)", amount : viewModel.revenueLiving, weight: .bold)
            AmountView(label : "BNC net imposable (après abattement)", amount : viewModel.revenueTaxable)
        }
    }
}

struct ActivityRevenuView_Previews: PreviewProvider {
    static var family = Family()
    static var model  = Model(fromBundle : Bundle.main)

    static var previews: some View {
        let aMember = family.members.items.first!

        return WorkRevenuView(adult: aMember as! Adult)
            .environmentObject(model)
    }
}
