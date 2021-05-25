//
//  FamilyDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

// MARK: - Afficher les détails d'un membre de la famille

struct PersonDetailView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var member     : Person
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State var showingSheet = false
    
    var body: some View {
        Form {
            Text(member.displayName).font(.headline)
            
            /// partie commune
            MemberAgeDateView(member: member)
            
            if let adult = member as? Adult {
                /// partie spécifique adulte
                HStack {
                    Text("Nombre d'enfants")
                    Spacer()
                    Text("\(adult.nbOfChildBirth)")
                }
                AdultDetailView()
                
            } else if member is Child {
                /// partie spécifique enfant
                ChildDetailView()
            }
        }
        .sheet(isPresented: $showingSheet) {
            PersonEditView(withInitialValueFrom: self.member)
        }
        .navigationTitle("Membre")
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(
                    action: { withAnimation { self.showingSheet = true } },
                    label : { Image(systemName: "square.and.pencil") }
                )
            }
        }
    }
}

struct PersonDetailView_Previews: PreviewProvider {
    static var family     = Family()
    static var patrimoin  = Patrimoin()
    static var simulation = Simulation()
    static var uiState    = UIState()
    static var anAdult   = family.members.first!
    static var aChild    = family.members.last!

    static var previews: some View {
        Group {
            // adult
            PersonDetailView()
                .environmentObject(family)
                .environmentObject(patrimoin)
                .environmentObject(simulation)
                .environmentObject(uiState)
                .environmentObject(anAdult)
            // enfant
            PersonDetailView()
                .environmentObject(family)
                .environmentObject(patrimoin)
                .environmentObject(simulation)
                .environmentObject(uiState)
                .environmentObject(aChild)
        }
        
    }
}
