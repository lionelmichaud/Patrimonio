//
//  AdultDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import PersonModel

// MARK: - MemberDetailView / AdultDetailView

struct AdultDetailView: View {
    var adult : Adult

    var body: some View {
        Group {
            /// Section: scénario
            LifeScenarioSection(adult: adult)
            
            /// Section: revenus
            RevenuSection(adult: adult)
            
            /// Section: succession
            InheritanceSection(adult: adult)
        }
    }
}

//struct AdultDetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        TestEnvir.loadTestFilesFromBundle()
//        let member = TestEnvir.familyTest.members[0]
//        // child
//        return Form {
//            AdultDetailView()
//                .environmentObject(TestEnvir.dataStoreTest)
//                .environmentObject(TestEnvir.modelTest)
//                .environmentObject(TestEnvir.uiStateTest)
//                .environmentObject(TestEnvir.familyTest)
//                .environmentObject(TestEnvir.expensesTest)
//                .environmentObject(TestEnvir.patrimoineTest)
//                .environmentObject(TestEnvir.simulationTest)
//                .environmentObject(member)
//        }
//    }
//}
