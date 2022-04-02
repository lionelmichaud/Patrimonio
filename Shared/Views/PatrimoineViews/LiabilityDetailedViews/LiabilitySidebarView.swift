//
//  LiabilityView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 05/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import Liabilities
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct LiabilitySidebarView: View {
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var patrimoine : Patrimoin
    private let indentLevel = 0
    private let label = "Passif"

    var totalDebt: Double {
        patrimoine.liabilities.value(atEndOf: CalendarCst.thisYear)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $uiState.patrimoineViewState.liabViewState.expandLiab) {
            LoanSidebarView()
            DebtSidebarView()
        } label: {
            LabeledValueRowView(label       : label,
                                 value       : totalDebt,
                                 indentLevel : indentLevel,
                                 header      : true,
                                 iconItem    : nil)
        }
    }
}

struct LiabilityView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromTemplate()
        return NavigationView {
            List {
                LiabilitySidebarView()
                    .environmentObject(TestEnvir.family)
                    .environmentObject(TestEnvir.patrimoine)
                    .environmentObject(TestEnvir.simulation)
                    .environmentObject(TestEnvir.uiState)
                    .previewDisplayName("LiabilityView")
            }
        }
    }
}
