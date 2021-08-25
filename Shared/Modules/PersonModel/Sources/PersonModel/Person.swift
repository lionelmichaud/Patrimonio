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
import ModelEnvironment
import DateBoundary

// MARK: - Tableau de Person

public typealias PersonArray = [Person]

// MARK: - Person
public class Person : ObservableObject, Identifiable, Codable, CustomStringConvertible {
    
    // MARK: - Nested types
    
    private enum CodingKeys : String, CodingKey {
        case sexe, name, birth_Date
    }
    
    // MARK: - Type properties
    
    static let coder = PersonCoderPreservingType()

    // MARK: - Properties
    
    public let id                          = UUID()
    public var sexe : Sexe                 = .male
    public var name : PersonNameComponents = PersonNameComponents() {
        didSet {
            displayName = personNameFormatter.string(from: name)
        }
    }
    @Published public var displayName : String = ""
    public var birthDate              : Date = Date() {
        didSet {
            displayBirthDate = mediumDateFormatter.string(from: birthDate)
            birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate)
        }
    }
    @Published public var displayBirthDate : String = ""
    var birthDateComponents                : DateComponents
    @Published public var ageOfDeath       : Int = CalendarCst.forever {
        didSet {
            yearOfDeath = birthDateComponents.year! + ageOfDeath
        }
    }
    public var yearOfDeath           : Int = 0
    public var ageComponents         : DateComponents { // computed
        Date.calendar.dateComponents([.year, .month, .day],
                                     from: birthDateComponents,
                                     to: CalendarCst.nowComponents)
    }
    public var ageAtEndOfCurrentYear : Int { // computed
        Date.calendar.dateComponents([.year],
                                     from: birthDateComponents,
                                     to: CalendarCst.endOfYearComp).year!
    }

    // MARK: - Conformance to CustomStringConvertible
    
    public var description: String {
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
    
    public init() {
        self.displayName         = personNameFormatter.string(from: name) // disSet not executed during init
        self.displayBirthDate    = mediumDateFormatter.string(from: birthDate) // disSet not executed during init
        self.birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate) // disSet not executed during init
        self.yearOfDeath         = birthDateComponents.year! + ageOfDeath // disSet not executed during init
    }
    
    // MARK: - Conformance to Decodable
    
    // reads from JSON
    required public init(from decoder: Decoder) throws {
        let container            = try decoder.container(keyedBy: CodingKeys.self)
        self.name                = try container.decode(PersonNameComponents.self, forKey: .name)
        self.sexe                = try container.decode(Sexe.self, forKey: .sexe)
        self.birthDate           = try container.decode(Date.self, forKey: .birth_Date)
        
        self.displayName         = personNameFormatter.string(from: name) // disSet not executed during init
        self.displayBirthDate    = mediumDateFormatter.string(from: birthDate) // disSet not executed during init
        self.birthDateComponents = Date.calendar.dateComponents([.year, .month, .day], from : birthDate) // disSet not executed during init
        self.yearOfDeath         = birthDateComponents.year! + self.ageOfDeath // disSet not executed during init
    }
    
    // MARK: - Conformance to Encodable
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(sexe, forKey: .sexe)
        try container.encode(birthDate, forKey: .birth_Date)
    }
    
    // MARK: - Methodes
    
    /// Initialise les propriétés qui ne peuvent pas l'être à la création
    /// quand le modèle n'est pas encore créé
    /// - Parameter model: modèle à utiliser
    func initialize(using model: Model) {
        setRandomPropertiesDeterministicaly(using: model)
    }
    
    public func age(atEndOf year: Int) -> Int {
        ageAtEndOfCurrentYear + (year - CalendarCst.thisYear)
    }
    
    public func age(atDate date: Date) -> DateComponents {
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
    public func isAlive(atEndOf year: Int) -> Bool {
        year < yearOfDeath
    }
    
    /// True si la personne décède dans l'année spécifiée
    /// - Parameter year: année testée
    public func isDeceased(during year: Int) -> Bool {
        let isAliveAtEndOfYear = self.isAlive(atEndOf: year)
        let wasAliveLastYear   = self.isAlive(atEndOf: year-1)
        return !isAliveAtEndOfYear && wasAliveLastYear
    }
    
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    public func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .deces:
                return yearOfDeath
            default:
                return nil
        }
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière aléatoires
    public func nextRandomProperties(using model: Model) {
        switch self.sexe {
            case .male:
                ageOfDeath = Int(model.humanLife.model!.menLifeExpectation.next())
                
            case .female:
                ageOfDeath = Int(model.humanLife.model!.womenLifeExpectation.next())
        }
        // on ne peut mourire à un age < à celui que l'on a déjà
        ageOfDeath = max(ageOfDeath, age(atEndOf: Date.now.year))
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière déterministe
    public func setRandomPropertiesDeterministicaly(using model: Model) {
        switch sexe {
            case .male:
                ageOfDeath = Int(model.humanLifeModel.menLifeExpectation.value(withMode: .deterministic))
                
            case .female:
                ageOfDeath = Int(model.humanLifeModel.womenLifeExpectation.value(withMode: .deterministic))
        }
        // on ne peut mourire à un age < à celui que l'on a déjà
        ageOfDeath = max(ageOfDeath, age(atEndOf: Date.now.year))
    }
    
    /// Actualiser les propriétés d'une personne à partir des valeurs modifiées
    /// des paramètres du modèle (valeur déterministes modifiées par l'utilisateur).
    public func updateMembersDterministicValues(
        _ menLifeExpectation    : Int,
        _ womenLifeExpectation  : Int,
        _ nbOfYearsOfdependency : Int,
        _ ageMinimumLegal       : Int,
        _ ageMinimumAGIRC       : Int
    ) {
        switch sexe {
            case .male:
                ageOfDeath = menLifeExpectation
                
            case .female:
                ageOfDeath = womenLifeExpectation
        }
    }
}

// MARK: Extensions

extension Person: Comparable {
    public static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.birthDate == rhs.birthDate
        
    }
    
    public static func < (lhs: Person, rhs: Person) -> Bool {
        // trier par date de naissance croissante
        lhs.birthDate < rhs.birthDate
    }
}
