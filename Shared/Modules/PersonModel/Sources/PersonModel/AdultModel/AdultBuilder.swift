//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 25/08/2021.
//

import Foundation
import AppFoundation
import FiscalModel
import UnemployementModel
import RetirementModel

/// Builder pour la Class Adult
///
/// Usage:
///
///     // créer un nouvel objet
///     let adult = AdultBuilder()
///                    .withSex(personViewModel.sexe)
///                    .named(givenName : givenName,
///                           familyName : familyName)
///                    .wasBorn(on: birthDate)
///                    .willDyeAtAgeOf(deathAge)
///                    .build()
///
///     // modifier un objet existant
///     AdultBuilder(for: adult)
///        .withSex(personViewModel.sexe)
///
public class AdultBuilder {
    private var adult: Adult
    
    // MARK: - Initializers
    
    public init() {
        adult = Adult()
    }
    
    public init(for adult: Adult) {
        self.adult = adult
    }
    
    // MARK: - Person properties
    
    public func withSex(_ sex: Sexe) -> AdultBuilder {
        adult.sexe            = sex
        adult.name.namePrefix = sex.displayString
        return self
    }
    
    public func named(givenName  : String,
                      familyName : String) -> AdultBuilder {
        guard givenName != "", familyName != "" else {
            fatalError("Cannot create a person with name = 'empty' ")
        }
        adult.name.givenName  = givenName
        adult.name.familyName = familyName.localizedUppercase
        return self
    }
    
    public func wasBorn(on birthDate: Date) -> AdultBuilder {
        guard birthDate < CalendarCst.now else {
            fatalError("Cannot create a person born in the future")
        }
        adult.birthDate = birthDate
        return self
    }
    
    public func willDyeAtAgeOf(_ ageOfDeath: Int) -> AdultBuilder {
        guard ageOfDeath > 0 else {
            fatalError("Cannot create a person with a death age <= 0")
        }
        adult.ageOfDeath = ageOfDeath
        return self
    }
    
    // MARK: - Adult properties
    
    @discardableResult
    public func receivesWorkIncome(_ workIncome: WorkIncomeType) -> AdultBuilder {
        adult.workIncome = workIncome
        return self
    }
    
    @discardableResult
    public func willCeaseActivities(on date    : Date,
                                    dueTo cause : Unemployment.Cause,
                                    withLayoffCompensationBonified: Double? = nil) -> AdultBuilder {
        adult.dateOfRetirement           = date
        adult.causeOfRetirement          = cause
        adult.layoffCompensationBonified = withLayoffCompensationBonified
        return self
    }
    
    @discardableResult
    public func willLiquidPension(atAge: (year: Int, month: Int, day: Int),
                                  lastKnownSituation: RegimeGeneralSituation) -> AdultBuilder {
        adult.setAgeOfPensionLiquidComp(year  : atAge.year,
                                        month : atAge.month,
                                        day   : atAge.day)
        adult.lastKnownPensionSituation = lastKnownSituation
        return self
    }
    
    @discardableResult
    public func willLiquidAgircPension(atAge: (year: Int, month: Int, day: Int),
                                       lastKnownSituation: RegimeAgircSituation) -> AdultBuilder {
        adult.setAgeOfAgircPensionLiquidComp(year  : atAge.year,
                                             month : atAge.month,
                                             day   : atAge.day)
        adult.lastKnownAgircPensionSituation = lastKnownSituation
        return self
    }
    
    @discardableResult
    public func willFaceDependencyDuring(_ nbOfYearOfDependency: Int) -> AdultBuilder {
        adult.nbOfYearOfDependency = nbOfYearOfDependency
        return self
    }
    
    @discardableResult
    public func adoptsSuccessionFiscalOption(_ fiscalOption: InheritanceFiscalOption) -> AdultBuilder {
        adult.fiscalOption = fiscalOption
        return self
    }
    
    // MARK: - Build the object
    
    public func build() -> Adult {
        adult
    }
}
