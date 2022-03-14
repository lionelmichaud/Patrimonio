//
//  PersonViewModel.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 28/04/2021.
//

import SwiftUI
import PersonModel

// MARK: - Person View Model

final class PersonViewModel: ObservableObject {
    @Published var familyName   = ""
    @Published var givenName    = ""
    @Published var sexe         = Sexe.male
    @Published var seniority    = Seniority.enfant
    @Published var birthDate    = Date()
    @Published var deathAge     = 0

    // MARK: - Initializers of ViewModel from Model

    init(from member: Person) {
        deathAge = member.ageOfDeath
    }

    // MARK: - Methods

    func update(member: Person) {
        member.ageOfDeath = deathAge
    }

    init() {    }
}
