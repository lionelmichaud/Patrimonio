//
//  FamilyMasterView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 08/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import PersonModel
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors

struct FamilySectionView : View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @Binding var showingSheet: Bool

    var body: some View {
        // bouton "ajouter"
        Button(
            action: {
                withAnimation {
                    self.showingSheet = true
                }
            },
            label: {
                Label(title: { Text("Ajouter une personne") },
                      icon : { Image(systemName: "person.fill.badge.plus") })
                    .foregroundColor(.accentColor)
            })

        Section {
            // liste des membres de la famille
            ForEach(family.members.items) { member in
                NavigationLink(destination: PersonDetailView().environmentObject(member)) {
                    Label(title: { MemberRowView(member: member) },
                          icon : { Image(systemName: "person.fill") })
                }
                .isDetailLink(true)
            }
            .onDelete(perform: deleteMembers)
            .onMove(perform: family.moveMembers)
            .listStyle(.sidebar)
        } header: {
            Text("Membres de la Famille")
        }
    }
    
    func deleteMembers(at offsets: IndexSet) {
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
        // supprimer le membre de la famille
        family.deleteMembers(at: offsets)
    }
}

struct MemberRowView : View {
    var member: Person
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(member.displayName)
                .font(.headline)
            MemberAgeDateView(member: member)
                .font(.caption)
        }
    }
}

struct MemberAgeDateView : View {
    var member    : Person
    
    var body: some View {
        AgeDateView(ageLabel  : (member.sexe == .male ? "Agé de"   : "Agée de"),
                    dateLabel : (member.sexe == .male ? "Né le"  : "Née le"),
                    age       : member.ageComponents.year!,
                    date      : member.displayBirthDate)
            .foregroundColor(.secondary)
    }
}

struct AgeDateView : View {
    var ageLabel  : String
    var dateLabel : String
    var age: Int
    var date: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(ageLabel)
                Spacer()
                Text("\(age) ans")
                    .foregroundColor(.primary)
            }
            HStack {
                Text(dateLabel)
                Spacer()
                Text(date)
                    .foregroundColor(.primary)
            }
        }
    }
}

struct FamilyListView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            List {
                FamilySectionView(showingSheet: .constant(false))
                    .environmentObject(TestEnvir.dataStore)
                    .environmentObject(TestEnvir.model)
                    .environmentObject(TestEnvir.uiState)
                    .environmentObject(TestEnvir.family)
                    .environmentObject(TestEnvir.expenses)
                    .environmentObject(TestEnvir.patrimoine)
                    .environmentObject(TestEnvir.simulation)
            }
        }
        .preferredColorScheme(.dark)
    }
}
