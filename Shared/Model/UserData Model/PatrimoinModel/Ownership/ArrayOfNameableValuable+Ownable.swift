//
//  ArrayOfNameableValuable+Ownable.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/04/2021.
//

import Foundation
import Files
import NamedValue

extension ArrayOfNameableValuable where E: Ownable {
    // MARK: - Initializers
    
    init(fileNamePrefix         : String = "",
         fromFolder folder      : Folder,
         with personAgeProvider : PersonAgeProvider?) throws {
        try self.init(fileNamePrefix : fileNamePrefix,
                      fromFolder     : folder)
        // injecter le délégué pour la méthode family.ageOf qui par défaut est nil à la création de l'objet
        for idx in 0..<items.count {
            if let personAgeProvider = personAgeProvider {
                items[idx].ownership.setDelegateForAgeOf(delegate: personAgeProvider.ageOf)
            }
        }
    }
    
    init(for aClass        : AnyClass,
         fileNamePrefix    : String = "",
         with personAgeProvider : PersonAgeProvider?) {
        self.init(for            : aClass,
                  fileNamePrefix : fileNamePrefix)
        // injecter le délégué pour la méthode family.ageOf qui par défaut est nil à la création de l'objet
        for idx in 0..<items.count {
            if let personAgeProvider = personAgeProvider {
                items[idx].ownership.setDelegateForAgeOf(delegate: personAgeProvider.ageOf)
            }
        }
    }
    
    /// Calcule la valeur d'un bien possédée par un personne donnée à une date donnée
    /// selon la régle générale ou selon la règle de l'IFI, de l'ISF, de la succession...
    ///  - Note:
    ///  Pour l'IFI:
    ///
    ///  Foyer taxable:
    ///  - adultes + enfants non indépendants
    ///
    ///  Patrimoine taxable à l'IFI =
    ///  - tous les actifs immobiliers dont un propriétaire ou usufruitier
    ///  est un membre du foyer taxable
    ///
    ///  Valeur retenue:
    ///  - actif détenu en pleine-propriété: valeur de la part détenue en PP
    ///  - actif détenu en usufuit : valeur de la part détenue en PP
    ///  - la résidence principale faire l’objet d’une décote de 30 %
    ///  - les immeubles que vous donnez en location peuvent faire l’objet d’une décote de 10 % à 30 % environ
    ///  - en indivision : dans ce cas, ils sont imposables à hauteur de votre quote-part minorée d’une décote de l’ordre de 30 % pour tenir compte des contraintes liées à l’indivision)
    ///
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - year: date d'évaluation
    ///   - evaluationMethod: méthode d'évaluation de la valeure des bien
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    func ownedValue(by ownerName     : String,
                    atEndOf year     : Int,
                    evaluationMethod : EvaluationMethod) -> Double {
        items.sumOfOwnedValues(by               : ownerName,
                               atEndOf          : year,
                               evaluationMethod : evaluationMethod)
    }
}
