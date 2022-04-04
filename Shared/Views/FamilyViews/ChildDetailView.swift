//
//  ChildDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import PersonModel
import FamilyModel

// MARK: - MemberDetailView / ChildDetailView

struct ChildDetailView: View {
    @EnvironmentObject private var member : Person
    @EnvironmentObject private var model  : Model

    var body: some View {
        let child = member as! Child
        return Section {
            HStack {
                Text("Age de décès estimé")
                Spacer()
                Text("\(member.ageOfDeath) ans en \(String(member.yearOfDeath))")
            }
            HStack {
                Text("Age d'entrée à l'université")
                Spacer()
                Text("\(child.ageOfUniversity) ans en \(String(child.dateOfUniversity.year))")
            }
            HStack {
                Text("Age d'indépendance financière")
                Spacer()
                Text("\(child.ageOfIndependence) ans en \(String(child.dateOfIndependence.year))")
            }
            NavigationLink(destination: PersonLifeLineView(from: self.member, using: model)) {
                Text("Ligne de vie").foregroundColor(.blue)
            }
        } header: {
            Text("SCENARIO").font(.subheadline)
        }
    }
}

struct ChildDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        let member = TestEnvir.family.members[2]
        return Form {
            ChildDetailView()
                .environmentObject(member)
                .environmentObject(TestEnvir.model)
        }
    }
}
