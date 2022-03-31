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
    @EnvironmentObject var patrimoine : Patrimoin
    private let indentLevel = 0
    private let label = "Passif"

    var body: some View {
        Section {
            LoanSidebarView()
            DebtSidebarView()
        } header: {
            LabeledValueRowView2(label       : label,
                                 value       : patrimoine.liabilities.value(atEndOf: CalendarCst.thisYear),
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
