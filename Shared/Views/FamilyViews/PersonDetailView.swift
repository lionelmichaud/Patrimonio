//
//  FamilyDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import PersonModel
import PatrimoineModel

// MARK: - Afficher les détails d'un membre de la famille

struct PersonDetailView: View {
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var member     : Person
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
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
            PersonEditView(withInitialValueFrom: self.member, using: model)
                .environmentObject(model)
                .environmentObject(family)
                .environmentObject(simulation)
                .environmentObject(patrimoine)
                .environmentObject(uiState)
        }
        .navigationTitle("Membre")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(
                    action: { withAnimation { self.showingSheet = true } },
                    label : {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                            Text("Modifier")
                        }
                    })
                    .capsuleButtonStyle()
            }
        }
    }
}

struct PersonDetailView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var family     = Family()
    static var patrimoin  = Patrimoin()
    static var simulation = Simulation()
    static var uiState    = UIState()
    static var anAdult    = family.members.items.first!
    static var aChild     = family.members.items.last!
    
    static var previews: some View {
        Group {
            // adult
            PersonDetailView()
                .environmentObject(model)
                .environmentObject(family)
                .environmentObject(patrimoin)
                .environmentObject(simulation)
                .environmentObject(uiState)
                .environmentObject(anAdult)
            // enfant
            PersonDetailView()
                .environmentObject(model)
                .environmentObject(family)
                .environmentObject(patrimoin)
                .environmentObject(simulation)
                .environmentObject(uiState)
                .environmentObject(aChild)
        }
        
    }
}
