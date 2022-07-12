//
//  MemberEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import FiscalModel
import HumanLifeModel
import UnemployementModel
import ModelEnvironment
import PersonModel
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors
import HelpersView

struct PersonEditView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @Environment(\.dismiss) private var dismiss

    private let member: Person
    
    @State private var showingSheet = false
    // Person
    @StateObject private var personViewModel: PersonViewModel
    // Child
    @State private var ageUniversity   : Int = 0
    @State private var ageIndependance : Int = 0
    // Adult
    @StateObject private var adultViewModel = AdultViewModel()
    
    var body: some View {
        VStack {
            /// Barre de titre
            HStack {
                Button("Annuler") {
                    dismiss()
                }.buttonStyle(.bordered)
                Spacer()
                Text("Modifier...").font(.title).fontWeight(.bold)
                Spacer()
                Button("OK", action: applyChanges)
                    .buttonStyle(.bordered)
                    .disabled(false)
            }.padding(.horizontal).padding(.top)
            
            /// Formulaire
            Form {
                Text(member.displayName).font(.headline)
                MemberAgeDateView(member: member).foregroundColor(.gray)
                if member is Adult {
                    /// Adulte
                    HStack {
                        Text("Nombre d'enfants")
                        Spacer()
                        Text("\((member as! Adult).nbOfChildBirth)")
                    }
                    AdultEditView(authorizeDeathAgeModification : true,
                                  personViewModel               : personViewModel,
                                  adultViewModel                : adultViewModel)
                    
                } else if member is Child {
                    /// Enfant
                    ChildEditView(authorizeDeathAgeModification : true,
                                  birthDate                     : member.birthDate,
                                  deathAge                      : $personViewModel.deathAge,
                                  ageUniversity                 : $ageUniversity,
                                  ageIndependance               : $ageIndependance)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    // MARK: - Initializer

    /// Initialise le ViewModel à partir des propriété d'un membre existant
    /// - Parameter member: le membre de la famille
    init(withInitialValueFrom member : Person,
         using model                 : Model) {
        self.member = member
        // Initialize Person ViewModel
        _personViewModel = StateObject(wrappedValue: PersonViewModel(from: member))

        // Child
        if let child = member as? Child {
            _ageUniversity   = State(initialValue: child.ageOfUniversity)
            _ageIndependance = State(initialValue: child.ageOfIndependence)
        } else {
            _ageUniversity   = State(initialValue: model.humanLifeModel.minAgeUniversity)
            _ageIndependance = State(initialValue: model.humanLifeModel.minAgeIndependance)
        }

        // Initialize Adult ViewModel
        if let adult = member as? Adult {
            _adultViewModel = StateObject(wrappedValue: AdultViewModel(from: adult))
        }
    }

    // MARK: - Methods
    
    /// Applique les modifications: recopie le ViewModel dans les propriétés d'un membre existant
    func applyChanges() {
        // Update Person from ViewModel
        personViewModel.update(member: member)
        
        // Child
        if let child = member as? Child {
            child.ageOfUniversity   = ageUniversity
            child.ageOfIndependence = ageIndependance
        }
        
        // Update Adult from ViewModel
        if let adult = member as? Adult {
            adultViewModel.update(adult: adult)
        }
        
        // mettre à jour le nombre d'enfant de chaque parent de la famille
        // et mémoriser l'existence d'une modification
        family.aMemberIsModified()
        
        // remettre à zéro la simulation et sa vue
        simulation.notifyComputationInputsModification()
        uiState.resetSimulationView()
        
        dismiss()
    }
}

// MARK: - Saisie enfant
struct ChildEditView : View {
    var authorizeDeathAgeModification: Bool
    
    @EnvironmentObject private var model: Model
    let birthDate                : Date
    @Binding var deathAge        : Int
    @Binding var ageUniversity   : Int
    @Binding var ageIndependance : Int
    
    var body: some View {
        Group {
            Section {
                if authorizeDeathAgeModification {
                    Stepper(value: $deathAge, in: Date().year - birthDate.year ... 100) {
                        HStack {
                            Text("Age de décès estimé")
                            Spacer()
                            Text("\(deathAge) ans").foregroundColor(.secondary)
                        }
                    }
                }
                Stepper(value: $ageUniversity,
                        in: model.humanLifeModel.minAgeUniversity ... model.humanLifeModel.minAgeIndependance) {
                    HStack {
                        Text("Age d'entrée à l'université")
                        Spacer()
                        Text("\(ageUniversity) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $ageIndependance,
                        in: model.humanLifeModel.minAgeIndependance ... 50) {
                    HStack {
                        Text("Age d'indépendance financière")
                        Spacer()
                        Text("\(ageIndependance) ans").foregroundColor(.secondary)
                    }
                }
            } header: {
                Text("SCENARIO").font(.subheadline)
            }
        }
    }
}

struct PersonEditView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        let anAdult = TestEnvir.family.members[0]
        let aChild  = TestEnvir.family.members[2]

        return Group {
            // adult
            PersonEditView(withInitialValueFrom : anAdult,
                           using                : TestEnvir.model)
                .environmentObject(TestEnvir.dataStore)
                .environmentObject(TestEnvir.model)
                .environmentObject(TestEnvir.uiState)
                .environmentObject(TestEnvir.family)
                .environmentObject(TestEnvir.expenses)
                .environmentObject(TestEnvir.patrimoine)
                .environmentObject(TestEnvir.simulation)
                .environmentObject(anAdult)
            // child
            PersonEditView(withInitialValueFrom : aChild,
                           using                : TestEnvir.model)
                .environmentObject(TestEnvir.dataStore)
                .environmentObject(TestEnvir.model)
                .environmentObject(TestEnvir.uiState)
                .environmentObject(TestEnvir.family)
                .environmentObject(TestEnvir.expenses)
                .environmentObject(TestEnvir.patrimoine)
                .environmentObject(TestEnvir.simulation)
                .environmentObject(aChild)
        }
    }
}
