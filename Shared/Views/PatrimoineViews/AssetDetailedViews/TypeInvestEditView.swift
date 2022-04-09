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
import HelpersView

// MARK: - Saisie du type d'investissement

struct TypeInvestEditView : View {
    @EnvironmentObject var family : Family
    @Binding var investType       : InvestementKind
    @State private var typeIndex  : Int
    @State private var isPeriodic : Bool
    @State private var clause     : Clause

    var body: some View {
        Group {
            CaseWithAssociatedValuePicker<InvestementKind>(caseIndex: $typeIndex, label: "")
                .pickerStyle(.segmented)
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
                self._clause     = State(initialValue: Clause())
        }
    }
}

struct TypeInvestEditView_Previews: PreviewProvider {
    static func clause() -> Clause {
        var theClause = Clause()
        theClause.isOptional        = false
        theClause.isDismembered     = true
        theClause.usufructRecipient = "M. Lionel MICHAUD"
        theClause.bareRecipients    = ["Enfant 1", "Enfant 2"]
        return theClause
    }
    static func investementKind() -> InvestementKind {
        InvestementKind.lifeInsurance(periodicSocialTaxes: true, clause: clause())
    }
    
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                EmptyView()
                Form {
                    TypeInvestEditView(investType: .constant(investementKind()))
                        .environmentObject(TestEnvir.family)
                }
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("TypeInvestEditView")
    }
}
