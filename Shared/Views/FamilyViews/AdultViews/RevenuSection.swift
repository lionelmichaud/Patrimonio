//
//  RevenuSection.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 09/07/2022.
//

import SwiftUI
import ModelEnvironment
import PersonModel
import HelpersView
import FiscalModel

// MARK: - MemberDetailView / AdultDetailView / RevenuSectionView

struct RevenuSection: View {
    var adult : Adult
    @EnvironmentObject private var model: Model

    // MARK: - View Model

    struct ViewModel {
        var unemployementAllocation          : (brut: Double, net: Double)?
        var pension                          = BrutNetTaxable(brut: 0.0, net: 0.0, taxable: 0.0)
        var hasUnemployementAllocationPeriod = false
        var revenueLiving                    = 0.0

        // MARK: - Initializers

        init() {
        }

        init(from adult: Adult, using model: Model) {
            hasUnemployementAllocationPeriod = adult.hasUnemployementAllocationPeriod
            unemployementAllocation          = adult.unemployementAllocation(using: model)
            pension                          = adult.pension(using: model)
            switch adult.workIncome {
                case .salary:
                    revenueLiving  = adult.workLivingIncome(using: model)
                case .turnOver:
                    revenueLiving  = adult.workLivingIncome(using: model)
                case .none: // nil
                    revenueLiving  = 0
            }
        }
    }

    // MARK: - Properties

    @State var viewModel = ViewModel()

    var body: some View {
        Section {
            DisclosureGroup {
                NavigationLink(destination: WorkRevenuView(adult: adult)) {
                    AmountView(label  : "Revenus d'activités professionnelles",
                               amount : viewModel.revenueLiving)
                    .foregroundColor(.blue)
                }

                // allocation chomage
                if viewModel.hasUnemployementAllocationPeriod {
                    NavigationLink(destination: UnemployementDetailView(adult: adult)) {
                        AmountView(label  : "Allocation chômage annuelle nette",
                                   amount : viewModel.unemployementAllocation!.net)
                        .foregroundColor(.blue)
                    }
                }
                
                // pension de retraite
                NavigationLink(destination: RetirementDetailView(adult: adult)) {
                    AmountView(label  : "Pension de retraite annuelle nette",
                               amount : viewModel.pension.net)
                    .foregroundColor(.blue)
                }
            } label: {
                Text("REVENUS").font(.headline)
            }
        }
        .onAppear(perform: onAppear)
    }

    // MARK: - Methods

    func onAppear() {
        viewModel = ViewModel(from: adult, using: model)
    }
}

struct RevenuSection_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        let member = TestEnvir.family.members[0]
        // child
        return Form {
            RevenuSection(adult: member as! Adult)
                .environmentObject(TestEnvir.model)
                .environmentObject(TestEnvir.patrimoine)
        }
    }
}
