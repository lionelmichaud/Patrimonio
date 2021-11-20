//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 18/10/2021.
//

import Foundation

extension Ownership {
    /// Calcule la part d'un revenu `totalRevenue`qui revient à une personne nommée `ownerName`
    /// en fonction de ses droits de propriété sur le bien.
    /// - Note:
    ///     Pour une personne et un bien donné
    ///     ownedRevenue =
    ///     * Bien non démembré = part de la valeur actuelle détenue en PP par la personne
    ///     * Bien démembré        = part de la valeur actuelle détenue en UF par la personne
    /// - Parameters:
    ///   - ownerName: nom de la personne
    ///   - totalRevenue: revenu total
    /// - Returns: part d'un revenu `totalRevenue`qui revient à une personne nommée `ownerName`
    public func ownedRevenue(by ownerName           : String,
                             ofRevenue totalRevenue : Double) -> Double {
        if isDismembered {
            // part de la valeur actuelle détenue en UF par la personne
            return usufructOwners[ownerName]?.ownedValue(from: totalRevenue) ?? 0
        } else {
            // pleine propriété => part de la valeur actuelle détenue en PP par la personne
            return fullOwners[ownerName]?.ownedValue(from: totalRevenue) ?? 0
        }
    }
    
    /// Calcule la part d'un revenu `totalRevenue`qui revient à un groupe de personnes
    /// nommées `ownersName` en fonction de leur droit respectif de propriété sur le bien.
    /// - Note:
    ///     Pour une personne et un bien donné
    ///     ownedRevenue =
    ///     * Bien non démembré = part de la valeur actuelle détenue en PP par la personne
    ///     * Bien démembré        = part de la valeur actuelle détenue en UF par la personne
    /// - Parameters:
    ///   - ownersName: noms des personnes
    ///   - totalRevenue: revenu total
    /// - Returns: part d'un revenu `totalRevenue`qui revient à une personne nommée `ownerName`
    func ownedRevenue(by ownersName          : [String],
                      ofRevenue totalRevenue : Double) -> Double {
        ownersName.reduce(0.0) { result, name in
            result + ownedRevenue(by: name, ofRevenue: totalRevenue)
        }
    }
    
    func ownedRevenueFraction(by ownerName: String) -> Double {
        if isDismembered {
            // part de la valeur actuelle détenue en UF par la personne
            return usufructOwners[ownerName]?.fraction ?? 0
        } else {
            // pleine propriété => part de la valeur actuelle détenue en PP par la personne
            return fullOwners[ownerName]?.fraction ?? 0
        }
    }
    
    public func ownedRevenueFraction(by ownersName: [String]) -> Double {
        ownersName.reduce(0.0) { result, name in
            result + ownedRevenueFraction(by: name)
        }
    }
    
    /// Calcule la valeur d'un bien (de valeur totale `totalValue`) possédée par un personne donnée
    /// à une date donnée `year` et selon le `evaluationContext` patrimonial, IFI, ISF, succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - totalValue: valeure totale du bien
    ///   - year: date d'évaluation
    ///   - evaluationContext: règles fiscales à utiliser pour le calcul
    /// - Returns: valeur du bien possédée (part d'usufruit + part de nue-prop)
    public func ownedValue(by ownerName       : String,
                           ofValue totalValue : Double,
                           atEndOf year       : Int,
                           evaluationContext  : EvaluationContext) -> Double {
        if isDismembered {
            switch evaluationContext {
                case .ifi, .isf :
                    // calcul de la part d'usufruit détenue
                    // on prend en compte la valeur en pleine propriété
                    return usufructOwners[ownerName]?.ownedValue(from: totalValue) ?? 0
                    
                case .lifeInsuranceTransmission:
                    // calcul de la part d'usufruit détenue = Quasi-Usufruit dans ce cas
                    // on prend en compte la valeur en pleine propriété pour la transmission en numéraire aux donatires
                    return usufructOwners[ownerName]?.ownedValue(from: totalValue) ?? 0

                case .legalSuccession, .lifeInsuranceSuccession, .patrimoine:
                    // démembrement
                    var usufructValue : Double = 0.0
                    var bareValue     : Double = 0.0
                    var value         : Double = 0.0
                    // calculer les valeurs des usufruit et nue prop
                    usufructOwners.forEach { usufruitier in
                        // prorata détenu par l'usufruitier
                        let ownedValue = totalValue * usufruitier.fraction / 100.0
                        // valeur de son usufuit
                        let usufruiterAge = ageOf!(usufruitier.name, year)
                        let (usuFruit, nueProp) =
                            try! Ownership
                            .demembrementProviderP
                            .demembrement(of              : ownedValue,
                                          usufructuaryAge : usufruiterAge)
                        usufructValue += usuFruit
                        bareValue     += nueProp
                    }
                    
                    // calcul de la valeur de la part de nue-propriété détenue
                    if let owner = bareOwners[ownerName] {
                        // on a trouvé un nue-propriétaire
                        value += owner.ownedValue(from: bareValue)
                    }
                    
                    // calcul de la valeur de la part d'usufuit détenue
                    if let owner = usufructOwners[ownerName] {
                        // on a trouvé un usufruitier nommé "ownerName"
                        // prorata de l'UF détenu par l'usufruitier
                        let ownedValue = totalValue * owner.fraction / 100.0
                        let usufruiterAge = ageOf!(owner.name, year)
                        
                        // valeur de son usufuit
                        value += try! Ownership
                            .demembrementProviderP
                            .demembrement(of              : ownedValue,
                                          usufructuaryAge : usufruiterAge).usufructValue
                    }
                    return value
            }
            
        } else {
            // pleine propriété
            return fullOwners[ownerName]?.ownedValue(from: totalValue) ?? 0
        }
    }
    
    /// Calcule la valeur d'un bien (de valeur totale `totalValue) possédée par chacun des propriétaires
    /// à une date donnée `year` et selon le `evaluationContext` patrimonial, IFI, ISF, succession...
    /// - Parameters:
    ///   - ownerName: nom de la personne recherchée
    ///   - totalValue: valeure totale du bien
    ///   - year: date d'évaluation
    ///   - evaluationContext: context d'évaluation à utiliser pour le calcul
    /// - Returns: [Nom : Valeur possédée]
    public func ownedValues(ofValue totalValue : Double,
                            atEndOf year       : Int,
                            evaluationContext  : EvaluationContext) -> NameValueDico {
        var dico = NameValueDico()
        if isDismembered {
            for owner in bareOwners {
                dico[owner.name] = ownedValue(by                : owner.name,
                                              ofValue           : totalValue,
                                              atEndOf           : year,
                                              evaluationContext : evaluationContext)
            }
            for owner in usufructOwners {
                dico[owner.name] = ownedValue(by                : owner.name,
                                              ofValue           : totalValue,
                                              atEndOf           : year,
                                              evaluationContext : evaluationContext)
            }
            
        } else {
            // valeur en pleine propriété
            for owner in fullOwners {
                dico[owner.name] = ownedValue(by                : owner.name,
                                              ofValue           : totalValue,
                                              atEndOf           : year,
                                              evaluationContext : evaluationContext)
            }
        }
        return dico
    }
}
