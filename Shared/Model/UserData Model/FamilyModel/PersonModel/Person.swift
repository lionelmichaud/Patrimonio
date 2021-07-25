//
//  Person.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import HumanLifeModel
import NamedValue
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git

// MARK: - Tableau de Person

typealias PersonArray = [Person]

// MARK: - Person
class Person : ObservableObject, Identifiable, Codable, CustomStringConvertible {
    
    // MARK: - Nested types

    private enum CodingKeys : String, CodingKey {
        case sexe, name, birth_Date
    }
    
    // MARK: - Type properties
    
    static let coder = PersonCoderPreservingType()
    
    // MARK: - Properties

    let id                    = UUID()
    let sexe                  : Sexe
    var name                  : PersonNameComponents {
        didSet {
            displayName = personNameFormatter.string(from: name)
        }
    }
    var birthDate             : Date {
        didSet {
            displayBirthDate = mediumDateFormatter.string(from: birthDate)
        }
    }
    var birthDateComponents   : DateComponents
    @Published var ageOfDeath : Int
    var yearOfDeath           : Int { // computed
        birthDateComponents.year! + ageOfDeath
    }
    var ageComponents         : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day],
                                     from: birthDateComponents,
                                     to: CalendarCst.nowComponents)
    }
    var ageAtEndOfCurrentYear : Int { // computed
        Date.calendar.dateComponents([.year],
                                     from: birthDateComponents,
                                     to: CalendarCst.endOfYearComp).year!
    }
    var displayName           : String = ""
    var displayBirthDate      : String = ""

    // MARK: - Conformance to CustomStringConvertible
    
    var description: String {
        return """
        
        NAME: \(displayName)
        - seniority: \(String(describing: type(of: self)))
        - sexe:      \(sexe)
        - birthdate: \(displayBirthDate)
        - age:       \(String(describing: ageComponents))
        - age of death:  \(ageOfDeath) ans
        - year of death: \(yearOfDeath)

        """
    }

    // MARK: - Initialization

    init(sexe       : Sexe,
         givenName  : String,
         familyName : String,
         birthDate  : Date,
         ageOfDeath : Int = CalendarCst.forever) {
        self.sexe                = sexe
        self.name                = PersonNameComponents()
        self.name.namePrefix     = sexe.displayString
        self.name.givenName      = givenName
        self.name.familyName     = familyName.localizedUppercase
        self.displayName         = personNameFormatter.string(from: name) // disSet not executed during init
        self.birthDate           = birthDate
        self.birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate)
        self.ageOfDeath          = ageOfDeath
    }
    
    // MARK: - Conformance to Decodable

    // reads from JSON
    required init(from decoder: Decoder) throws {
        let container            = try decoder.container(keyedBy: CodingKeys.self)
        self.name                = try container.decode(PersonNameComponents.self, forKey: .name)
        displayName = personNameFormatter.string(from: name) // disSet not executed during init
        self.sexe                = try container.decode(Sexe.self, forKey: .sexe)
        self.birthDate           = try container.decode(Date.self, forKey: .birth_Date)
        displayBirthDate = mediumDateFormatter.string(from: birthDate) // disSet not executed during init
        self.birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate)
        self.ageOfDeath          = 81
    }
    
    // MARK: - Conformance to Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(sexe, forKey: .sexe)
        try container.encode(birthDate, forKey: .birth_Date)
    }

    // MARK: - Methodes
    
    /// Initialise les propriétés qui ne peuvent pas l'être à la création
    /// quand le modèle n'est pas encore créé
    /// - Parameter model: modèle à utiliser
    func initialize(usingModel model: Model) {
        // initialiser l'age de décès avec la valeur moyenne déterministe
        switch self.sexe {
            case .male:
                self.ageOfDeath = Int(model.humanLife!.model.menLifeExpectation.value(withMode: .deterministic))
                
            case .female:
                self.ageOfDeath = Int(model.humanLife!.model.womenLifeExpectation.value(withMode: .deterministic))
        }
    }

    func age(atEndOf year: Int) -> Int {
        ageAtEndOfCurrentYear + (year - CalendarCst.thisYear)
    }
    
    func age(atDate date: Date) -> DateComponents {
        let dateComp = Date.calendar.dateComponents([.year, .month, .day],
                                                    from: date)
        return Date.calendar.dateComponents([.year, .month, .day],
                                            from: birthDateComponents,
                                            to: dateComp)
    }
    
    /// True si la personne est encore vivante à la fin de l'année donnée
    /// - Parameter year: année
    /// - Returns: True si la personne est encore vivante
    /// - Warnings: la personne n'est pas vivante l'année du décès
    func isAlive(atEndOf year: Int) -> Bool {
        year < yearOfDeath
    }
    
    /// True si la personne décède dans l'année spécifiée
    /// - Parameter year: année testée
    func isDeceased(during year: Int) -> Bool {
        let isAliveAtEndOfYear = self.isAlive(atEndOf: year)
        let wasAliveLastYear   = self.isAlive(atEndOf: year-1)
        return !isAliveAtEndOfYear && wasAliveLastYear
    }
    
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .deces:
                return yearOfDeath
            default:
                return nil
        }
    }
        
    /// Réinitialiser les prioriétés aléatoires des membres
    func nextRandomProperties(using model: Model) {
        switch self.sexe {
            case .male:
                ageOfDeath = Int(model.humanLife!.model.menLifeExpectation.next())
                
            case .female:
                ageOfDeath = Int(model.humanLife!.model.womenLifeExpectation.next())
        }
        // on ne peut mourire à un age < à celui que l'on a déjà
        ageOfDeath = max(ageOfDeath, age(atEndOf: Date.now.year))
    }
}

// MARK: Extensions

extension Person: Comparable {
    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.birthDate == rhs.birthDate

    }
    
    static func < (lhs: Person, rhs: Person) -> Bool {
        // trier par date de naissance croissante
        lhs.birthDate < rhs.birthDate
    }
}
