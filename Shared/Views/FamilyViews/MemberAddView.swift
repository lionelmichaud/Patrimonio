//
//  FamilyAddView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import HumanLifeModel

// MARK: - Saisie du nouveau membre de la famille

struct MemberAddView: View {
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var patrimoine : Patrimoin
    @EnvironmentObject var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem : AlertItem?
    // Person
    @StateObject var personViewModel = PersonViewModel()
    // Child
    @State private var ageUniversity   = HumanLife.model.minAgeUniversity
    @State private var ageIndependance = HumanLife.model.minAgeIndependance
    // Adult
    @StateObject var adultViewModel = AdultViewModel()
    
    var body: some View {
        VStack {
            /// Barre de titre
            HStack {
                Button(action: { self.presentationMode.wrappedValue.dismiss() },
                       label: { Text("Annuler") })
                    .capsuleButtonStyle()
                
                Spacer()
                Text("Ajouter...").font(.title).fontWeight(.bold)
                Spacer()
                
                Button(action: addMember,
                       label: { Text("OK") })
                    .capsuleButtonStyle()
                    .disabled(!formIsValid())
            }
            .padding(.horizontal)
            .padding(.top)
            
            /// Formulaire
            Form {
                CiviliteEditView(personViewModel: personViewModel)
                    .onChange(of: personViewModel.seniority) { newState in
                        // pas plus de deux adultes dans une famille
                        if newState == .adult && family.nbOfAdults == 2 {
                            self.alertItem = AlertItem(title         : Text("Pas plus de 2 adultes par famille"),
                                                       dismissButton : .default(Text("OK")))
                            personViewModel.seniority = .enfant
                        }
                    }
                    .alert(item: $alertItem, content: myAlert)

                if formIsValid() {
                    if personViewModel.seniority == .adult {
                        AdultEditView(personViewModel: personViewModel,
                                      adultViewModel : adultViewModel)
                        
                    } else {
                        ChildEditView(birthDate       : personViewModel.birthDate,
                                      deathAge        : $personViewModel.deathAge,
                                      ageUniversity   : $ageUniversity,
                                      ageIndependance : $ageIndependance)
                    }
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    /// Création du nouveau membre et ajout à la famille
    func addMember() {
        // remettre à zéro la simulation et sa vue
        simulation.reset()
        uiState.reset()
        
        switch personViewModel.seniority {
            case .adult  :
                // creation du nouveau membre Adult
                let newMember = Adult(sexe       : personViewModel.sexe,
                                      givenName  : personViewModel.givenName,
                                      familyName : personViewModel.familyName.uppercased(),
                                      birthDate  : personViewModel.birthDate,
                                      ageOfDeath : personViewModel.deathAge)
                adultViewModel.updateFromViewModel(adult: newMember)
                
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
            
            case .enfant :
                // creation du nouveau membre Enfant
                let newMember = Child(sexe       : personViewModel.sexe,
                                      givenName  : personViewModel.givenName,
                                      familyName : personViewModel.familyName.uppercased(),
                                      birthDate  : personViewModel.birthDate,
                                      ageOfDeath : personViewModel.deathAge)
                newMember.ageOfUniversity = ageUniversity
                newMember.ageOfIndependence = ageIndependance
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
        }
        
        self.presentationMode.wrappedValue.dismiss()
    }
    
    /// Vérifie que la formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    func formIsValid() -> Bool {
        if personViewModel.familyName.allSatisfy({ $0 == " " }) ||
            personViewModel.givenName.allSatisfy({ $0 == " " })            // genre.allSatisfy({ $0 == " " })
        {
            return false
        }
        return true
    }
}

// MARK: - Saisie des civilités du nouveau membre

struct CiviliteEditView : View {
    @ObservedObject var personViewModel: PersonViewModel
    
    var body: some View {
        Section {
            CasePicker(pickedCase: $personViewModel.sexe, label: "Genre")
                .pickerStyle(SegmentedPickerStyle())
            CasePicker(pickedCase: $personViewModel.seniority, label: "Seniorité")
                .pickerStyle(SegmentedPickerStyle())
            HStack {
                Text("Nom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $personViewModel.familyName)
            }
            HStack {
                Text("Prénom")
                    .frame(width: 70, alignment: .leading)
                TextField("obligatoire", text: $personViewModel.givenName)
            }
            DatePicker(selection: $personViewModel.birthDate,
                       in: 100.years.ago!...Date(),
                       displayedComponents: .date,
                       label: { Text("Date de naissance") })
        }
    }
}

struct MemberAddView_Previews: PreviewProvider {
    static var family     = Family()
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()
    
    static var previews: some View {
        MemberAddView()
            .environmentObject(family)
            .environmentObject(simulation)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
    }
}
