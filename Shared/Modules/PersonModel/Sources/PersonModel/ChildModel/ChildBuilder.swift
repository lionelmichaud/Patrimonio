//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 25/08/2021.
//

import Foundation
import AppFoundation

/// Builder pour la Class Child
public class ChildBuilder {
    private var child: Child = Child()
    
    // MARK: - Initializers
    
    public init() { }
    
    // MARK: - Person properties
    
    public func withSex(_ sex: Sexe) -> ChildBuilder {
        child.sexe            = sex
        child.name.namePrefix = sex.displayString
        return self
    }
    
    public func named(givenName  : String,
                      familyName : String) -> ChildBuilder {
        guard givenName != "", familyName != "" else {
            fatalError("Cannot create a person with name = 'empty' ")
        }
        child.name.givenName  = givenName
        child.name.familyName = familyName.localizedUppercase
        return self
    }
    
    public func wasBorn(on birthDate: Date) -> ChildBuilder {
        guard birthDate < CalendarCst.now else {
            fatalError("Cannot create a person born in the future")
        }
        child.birthDate = birthDate
        return self
    }
    
    public func willDyeAtAgeOf(_ ageOfDeath: Int) -> ChildBuilder {
        guard ageOfDeath > 0 else {
            fatalError("Cannot create a person with a death age <= 0")
        }
        child.ageOfDeath = ageOfDeath
        return self
    }
    
    // MARK: - Child properties
    
    @discardableResult
    public func entersUniversityAtAgeOf(_ age: Int) -> ChildBuilder {
        guard age > 0 else {
            fatalError("Cannot create a child entering university at age <= 0")
        }
        child.ageOfUniversity = age
        return self
    }
    
    @discardableResult
    public func willBeIndependantAtAgeOf(_ age: Int) -> ChildBuilder {
        guard age > 0 else {
            fatalError("Cannot create a child independant at age <= 0")
        }
        child.ageOfIndependence = age
        return self
    }
    
    // MARK: - Build the object
    
    public func build() -> Child {
        child
    }
    
}
