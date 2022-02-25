//
//  TypeInvestEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Ownership
import AssetsModel
import PersonModel
import FamilyModel

// MARK: - Saisie du type d'investissement

struct TypeInvestEditView : View {
    @EnvironmentObject var family : Family
    @Binding var investType       : InvestementKind
    @State private var typeIndex  : Int
    @State private var isPeriodic : Bool
    @State private var clause     : LifeInsuranceClause

    var body: some View {
        Group {
            CaseWithAssociatedValuePicker<InvestementKind>(caseIndex: $typeIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: typeIndex) { newValue in
                    switch newValue {
                        case InvestementKind.pea.id:
                            self.investType = .pea
                        case InvestementKind.other.id:
                            self.investType = .other
                        case InvestementKind.lifeInsurance().id:
                            self.investType = .lifeInsurance(periodicSocialTaxes: self.isPeriodic,
                                                             clause             : self.clause)
                        default:
                            fatalError("InvestementType : Case out of bound")
                    }
                }
            if typeIndex == InvestementKind.lifeInsurance().id {
                Toggle("Prélèvement sociaux annuels", isOn: $isPeriodic)
                    .onChange(of: isPeriodic) { newValue in
                        self.investType = .lifeInsurance(periodicSocialTaxes: newValue,
                                                         clause             : self.clause)
                    }
                Toggle("Clause bénéficiaire à option (non démembrable)", isOn: $clause.isOptional)
                    .onChange(of: clause) { newValue in
                        var newClause = newValue
                        if newClause.isOptional {
                            newClause.isDismembered = false
                        }
                        self.investType = .lifeInsurance(periodicSocialTaxes: isPeriodic,
                                                         clause             : newClause)
                    }
                if !clause.isOptional {
                    Toggle("Clause bénéficiaire démembrée", isOn: $clause.isDismembered)
                }
                ClauseView(clause: $clause)
            }
        }
    }
    
    // MARK: - Initializer
    
    init(investType: Binding<InvestementKind>) {
        self._investType = investType
        self._typeIndex  = State(initialValue: investType.wrappedValue.id)
        switch investType.wrappedValue {
            case .lifeInsurance(let periodicSocialTaxes, let clause):
                self._isPeriodic = State(initialValue: periodicSocialTaxes)
                self._clause     = State(initialValue: clause)
                
            default:
                self._isPeriodic = State(initialValue: false)
                self._clause     = State(initialValue: LifeInsuranceClause())
        }
    }

    // MARK: - Methods

    private func bareRecipientsSummary(clause: LifeInsuranceClause) -> String {
        if clause.bareRecipients.isEmpty {
            return ""
        } else if clause.bareRecipients.count == 1 {
            return clause.bareRecipients.first!
        } else {
            return "\(clause.bareRecipients.count) personnes"
        }
    }

    private func fullRecipientsSummary(clause: LifeInsuranceClause) -> String {
        if clause.fullRecipients.isEmpty {
            return ""
        } else if clause.fullRecipients.count == 1 {
            return clause.fullRecipients.first!.name
        } else {
            return "\(clause.fullRecipients.count) personnes"
        }
    }
}

struct TypeInvestEditView_Previews: PreviewProvider {
    static var family     = Family()

    static var previews: some View {
        Form {
            TypeInvestEditView(investType: .constant(InvestementKind.lifeInsurance()))
                .environmentObject(family)
        }
        .previewDisplayName("TypeInvestEditView")
    }
}
