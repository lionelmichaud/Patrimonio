//
//  Child.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import ModelEnvironment
import DateBoundary

/// Un enfant
///
/// Usage:
///
///     let child = Child(from: decoder)
///     child.initialize(using: model)
///
///     print(String(describing: child)
///
///     child.nextRandomProperties(using: model)
///     child.nextRandomProperties(using: model)
///
///     child.setRandomPropertiesDeterministicaly(using: model)
///
public final class Child: Person {
    
    // MARK: - nested types
    
    private enum CodingKeys : String, CodingKey {
        case age_Of_University, age_Of_Independence
    }
    
    // MARK: - properties
    
    @Published public var ageOfUniversity: Int = 18
    public var dateOfUniversity    : Date { // computed
        dateOfUniversityComp.date!
    }
    public var dateOfUniversityComp: DateComponents { // computed
        DateComponents(calendar : Date.calendar,
                       year     : birthDate.year + ageOfUniversity,
                       month    : 09,
                       day      : 30)
    }
    var yearAtEntryToUniversity: Int {
        birthDate.year + ageOfUniversity
    }
    
    @Published public var ageOfIndependence: Int = 24
    public var dateOfIndependence    : Date { // computed
        dateOfIndependenceComp.date!
    }
    public var dateOfIndependenceComp: DateComponents { // computed
        DateComponents(calendar : Date.calendar,
                       year     : birthDate.year + ageOfIndependence,
                       month    : 09,
                       day      : 30)
    }
    var yearOfIndependence: Int {
        birthDate.year + ageOfIndependence
    }
    public override var description: String {
        super.description +
            """
        - age at university:  \(ageOfUniversity) ans
        - date of university: \(dateOfUniversity.stringMediumDate)
        - age of independance:  \(ageOfIndependence) ans
        - date of independance: \(dateOfIndependence.stringMediumDate) \n
        """
    }
    
    // MARK: - initialization
    
    required init(from decoder: Decoder) throws {
        // Get our container for this subclass' coding keys
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ageOfUniversity   = try container.decode(Int.self, forKey : .age_Of_University)
        ageOfIndependence = try container.decode(Int.self, forKey : .age_Of_Independence)
        
        // Get superDecoder for superclass and call super.init(from:) with it
        //let superDecoder = try container.superDecoder()
        try super.init(from: decoder)
    }
    
    public override init() {
        super.init()
    }
    
    // MARK: - methods
    
    public override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(ageOfUniversity, forKey: .age_Of_University)
        try container.encode(ageOfIndependence, forKey: .age_Of_Independence)
    }
    
    /// true si l'année est postérieure à l'année d'entrée à l'université et avant indépendance financière
    /// - Parameter year: année
    public final func isAtUniversity(during year: Int) -> Bool {
        (yearAtEntryToUniversity < year) && !isIndependant(during: year)
    }
    
    /// true si l'année est postérieure à l'année d'indépendance financière
    /// - Parameter year: année
    public final func isIndependant(during year: Int) -> Bool {
        yearOfIndependence < year
    }
    
    /// True si l'enfant fait encore partie du foyer fiscal pendant l'année donnée
    public final func isFiscalyDependant(during year: Int) -> Bool {
        let isAlive     = self.isAlive(atEndOf: year)
        let isDependant = !self.isIndependant(during: year)
        let age         = self.age(atEndOf: year - 1) // au début de l'année d'imposition
        return isAlive && ((age <= 21) || (isDependant && age <= 25))
    }
    
    /// Année ou a lieu l'événement recherché
    /// - Parameter event: événement recherché
    /// - Returns: Année ou a lieu l'événement recherché, nil si l'événement n'existe pas
    public override final func yearOf(event: LifeEvent) -> Int? {
        switch event {
            case .debutEtude:
                return dateOfUniversity.year
                
            case .independance:
                return dateOfIndependence.year
                
            case .dependence:
                return nil
                
            case .deces:
                return super.yearOf(event: event)
                
            case .cessationActivite:
                return nil
                
            case .liquidationPension:
                return nil
        }
    }
    
    /// Réinitialiser les prioriétés variables des membres de manière aléatoires
    /// - Warning: les enfants ont toujours une date de décès déterministe
    public override final func nextRandomProperties(using model: Model) {
        super.setRandomPropertiesDeterministicaly(using: model)
    }

}
