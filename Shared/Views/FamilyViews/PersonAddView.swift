//
//  FamilyAddView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/03/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import HumanLifeModel
import ModelEnvironment
import PersonModel
import PatrimoineModel

// MARK: - Saisie du nouveau membre de la famille

struct PersonAddView: View {
    //@Environment(\.managedObjectContext) var moc
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    @Environment(\.presentationMode) var presentationMode
    @State private var alertItem : AlertItem?
    // Person
    @StateObject var personViewModel = PersonViewModel()
    // Child
    @State private var ageUniversity   : Int = 0
    @State private var ageIndependance : Int = 0
    // Adult
    @StateObject var adultViewModel = AdultViewModel()
    
    init(using model: Model) {
        _ageUniversity   = State(initialValue: model.humanLifeModel.minAgeUniversity)
        _ageIndependance = State(initialValue: model.humanLifeModel.minAgeIndependance)
        _adultViewModel  = StateObject(wrappedValue: AdultViewModel(from: model))
    }
    
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
                    switch personViewModel.seniority {
                        case .adult:
                            AdultEditView(authorizeDeathAgeModification : false,
                                          personViewModel               : personViewModel,
                                          adultViewModel                : adultViewModel)

                        case .enfant:
                            ChildEditView(authorizeDeathAgeModification : false,
                                          birthDate                     : personViewModel.birthDate,
                                          deathAge                      : $personViewModel.deathAge,
                                          ageUniversity                 : $ageUniversity,
                                          ageIndependance               : $ageIndependance)
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
        
        // initialiser l'espérace de vie à partir du modèle
        let deathAge: Int
        switch personViewModel.sexe {
            case .male:
                deathAge = Int(model.humanLife.model!.menLifeExpectation.value(withMode: .deterministic))
            case .female:
                deathAge = Int(model.humanLife.model!.womenLifeExpectation.value(withMode: .deterministic))
        }

        switch personViewModel.seniority {
            case .adult  :
                // creation du nouveau membre Adult
                let newMember = AdultBuilder()
                    .withSex(personViewModel.sexe)
                    .named(givenName  : personViewModel.givenName,
                           familyName : personViewModel.familyName.uppercased())
                    .wasBorn(on: personViewModel.birthDate)
                    .willDyeAtAgeOf(deathAge)
                    .build()
                adultViewModel.update(adult: newMember)
                
                // ajout du nouveau membre à la famille
                family.addMember(newMember)
            
            case .enfant :
                // creation du nouveau membre Enfant
                let newMember = ChildBuilder()
                    .withSex(personViewModel.sexe)
                    .named(givenName  : personViewModel.givenName,
                           familyName : personViewModel.familyName.uppercased())
                    .wasBorn(on: personViewModel.birthDate)
                    .willDyeAtAgeOf(deathAge)
                    .entersUniversityAtAgeOf(ageUniversity)
                    .willBeIndependantAtAgeOf(ageIndependance)
                    .build()
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
    static var model      = Model(fromBundle: Bundle.main)
    static var simulation = Simulation()
    static var patrimoine = Patrimoin()
    static var uiState    = UIState()
    
    static var previews: some View {
        PersonAddView(using: model)
            .environmentObject(family)
            .environmentObject(model)
            .environmentObject(simulation)
            .environmentObject(patrimoine)
            .environmentObject(uiState)
    }
}
