//
//  Demembrement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
import Foundation
import os
import AppFoundation
import FiscalModel

let customLogOwnership = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Ownership")

// MARK: - Enumération de Nature d'une propriété

public enum OwnershipNature: String, PickableEnumP {
    case generatesRevenue = "Uniquement les biens génèrant revenu/dépense (possédés en PP ou en UF au moins en partie)"
    case sellable         = "Uniquement les biens cessibles (possédés en PP au moins en partie)"
    case all              = "Tous les biens (possédés en UF, NP ou PP au moins en partie)"
    
    public var pickerString: String {
        return self.rawValue
    }
}

public enum EvaluatedFraction: String, PickableEnumP {
    case totalValue = "Valeur totale du bien"
    case ownedValue = "Valeur patrimoniale de la fraction possédée du bien"

    public var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Enumération de Contexte d'évaluation d'un Patrmoine (régles fiscales à appliquer)

public enum EvaluationContext: String, PickableEnumP {
    case ifi                     = "IFI"
    case isf                     = "ISF"
    case legalSuccession         = "Succession Légale"
    case lifeInsuranceSuccession = "Succession Assurance Vie"
    case patrimoine              = "Patrimoniale"
    
    public var pickerString: String {
        return self.rawValue
    }
}

// MARK: - La répartition des droits de propriété d'un bien entre personnes

public enum OwnershipError: Error {
    case tryingToDismemberUnUndismemberedAsset
    case invalidOwnership
}

// MARK: - Struct définissant les droits de propriété d'un bien

public struct Ownership {
    
    // MARK: - Static Properties
    
    // dependencies
    private static var demembrementProviderP : DemembrementProviderP!
    
    /// Dependency Injection: Setter Injection
    public static func setDemembrementProviderP(_ demembrementProviderP : DemembrementProviderP) {
        Ownership.demembrementProviderP = demembrementProviderP
    }
    
    // MARK: - Properties
    
    public var fullOwners     : Owners = []
    public var bareOwners     : Owners = []
    public var usufructOwners : Owners = []
    // fonction qui donne l'age d'une personne à la fin d'une année donnée
    var ageOf          : ((_ name: String, _ year: Int) -> Int)?
    public var isDismembered: Bool = false {
        didSet {
            if isDismembered {
                usufructOwners = fullOwners
                bareOwners     = fullOwners
            }
        }
    }
    public var isValid: Bool {
        if isDismembered {
            return (bareOwners.isNotEmpty && bareOwners.isvalid) &&
                (usufructOwners.isNotEmpty && usufructOwners.isvalid)
        } else {
            return fullOwners.isNotEmpty && fullOwners.isvalid
        }
    }
    
    // MARK: - Initializers
    
    public init(ageOf: @escaping (_ name: String, _ year: Int) -> Int) {
        self.ageOf = ageOf
    }
    
    public init() {    }
    
    // MARK: - Methods
    
    public mutating func setDelegateForAgeOf(delegate: ((_ name: String, _ year: Int) -> Int)?) {
        ageOf = delegate
    }
    
    /// Calcule les valeurs démembrées d'un bien en fonction de la date d'évaluation
    /// et donc en fonction de l'age du propréitaire du bien à démembrer
    /// - Parameters:
    ///   - totalValue: valeur du bien en pleine propriété
    ///   - year: date d'évaluation
    /// - Returns: valeurs de l'usufruit et de la nue-propriété
    func demembrement(ofValue totalValue : Double,
                      atEndOf year       : Int) throws
    -> (usufructValue : Double,
        bareValue     : Double) {
        guard isDismembered else {
            customLogOwnership.log(level: .error, "Tentative de calul de valeur démembrée d'un bien qui ne l'est pas")
            throw OwnershipError.tryingToDismemberUnUndismemberedAsset
        }
        guard isValid else {
            customLogOwnership.log(level: .error, "Tentative de calul de valeur démembrée d'un bien dont le démembrement n'est pas valide")
            throw OwnershipError.invalidOwnership
        }
        guard ageOf != nil else {
            customLogOwnership.log(level: .fault, "Pas de closure permettant de calculer l'age d'un propriétaire")
            fatalError("Pas de closure permettant de calculer l'age d'un propriétaire")
        }
        
        // démembrement
        var usufructValue : Double = 0.0
        var bareValue     : Double = 0.0
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
        return (usufructValue: usufructValue, bareValue: bareValue)
    }
    
    /// Idem demembrement mais sous forme de % entre UF et NP en fonction de la date d'évaluation
    /// et donc en fonction de l'age du propréiatire du bien à démembrer
    public func demembrementPercentage(atEndOf year: Int) throws
    -> (usufructPercent  : Double,
        bareValuePercent : Double) {
        let dem = try demembrement(ofValue: 100.0, atEndOf: year)
        return (usufructPercent : dem.usufructValue,
                bareValuePercent: dem.bareValue)
    }
    
    /// Calcule la part d'un revenu `totalRevenue`qui revient à une personne nommée `ownerName`
    /// en fonction de ses droits de propriété sur le bien.
    /// - Note:
    ///     Pour une personne et un bien donné Part =
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
    ///     Pour une personne et un bien donné Part =
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
    
    /// Calcule la valeur d'un bien (de valeur totale `totalValue) possédée par un personne donnée
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
                    // calcul de la part de pleine-propiété détenue
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
                    
                    // calcul de la part de nue-propriété détenue
                    if let owner = bareOwners[ownerName] {
                        // on a trouvé un nue-propriétaire
                        value += owner.ownedValue(from: bareValue)
                    }
                    
                    // calcul de la part d'usufuit détenue
                    if let owner = usufructOwners[ownerName] {
                        // on a trouvé un usufruitier
                        // prorata détenu par l'usufruitier
                        let ownedValue = totalValue * owner.fraction / 100.0
                        // valeur de son usufuit
                        let usufruiterAge = ageOf!(owner.name, year)
                        
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
                            evaluationContext  : EvaluationContext) -> [String : Double] {
        var dico: [String : Double] = [:]
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
    
    /// Factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
    mutating func groupShares() {
        if isDismembered {
            fullOwners = [ ]
            usufructOwners.groupShares()
            bareOwners.groupShares()
        } else {
            fullOwners.groupShares()
            usufructOwners = [ ]
            bareOwners     = [ ]
        }
        // regrouper usufruit et nue-propriété si possible
        if isDismembered {
            if usufructOwners == bareOwners {
                isDismembered  = false
                fullOwners     = bareOwners
                usufructOwners = [ ]
                bareOwners     = [ ]
            }
        }
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    /// - Warning: Ne donne pas le bon résultat pour un bien indivis.
    /// - Throws:
    ///   - OwnershipError.invalidOwnership: le ownership avant ou après n'est pas valide
    public mutating func transferOwnershipOf(decedentName       : String, // swiftlint:disable:this cyclomatic_complexity
                                             chidrenNames       : [String]?,
                                             spouseName         : String?,
                                             spouseFiscalOption : InheritanceFiscalOption?) throws {
        guard isValid else {
            customLogOwnership.log(level: .error, "Tentative de transfert de propriéta avec 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le bien est démembré
            if let spouseName = spouseName {
                // TODO: - Gérer correctement les transferts de propriété des biens indivis et démembrés
                // (1) il y a un conjoint survivant
                //     le défunt peut être usufruitier et/ou nue-propriétaire
                
                // USUFRUIT
                if hasAnUsufructOwner(named: decedentName) {
                    // (a) le défunt était usufruitier
                    if hasABareOwner(named: decedentName) {
                        // (1) le défunt était aussi nue-propriétaire
                        // le défunt possèdait encore la UF + NP et les deux sont transmis
                        // selon l'option du conjoint survivant comme une PP
                        transferUsufructAndBareOwnership(of                 : decedentName,
                                                         toSpouse           : spouseName,
                                                         toChildren         : chidrenNames,
                                                         spouseFiscalOption : spouseFiscalOption)
                        
                    } else {
                        // (2) le défunt était seulement usufruitier
                        // le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
                        // cad que les nues-propriétaires deviennent PP
                        transferUsufruct(of         : decedentName,
                                         toChildren : chidrenNames)
                        
                    }
                } else if bareOwners.contains(ownerName: decedentName) {
                    // (b) le défunt était seulement nue-propriétaire
                    // NUE-PROPRIETE
                    // retirer le défunt de la liste des nue-propriétaires
                    // et répartir sa part sur ses héritiers selon l'option retenue par le conjoint survivant
                    transferBareOwnership(of                 : decedentName,
                                          toSpouse           : spouseName,
                                          toChildren         : chidrenNames,
                                          spouseFiscalOption : spouseFiscalOption)
                    
                } // (c) sinon on ne fait rien
                
            } else if let chidrenNames = chidrenNames {
                // (2) il n'y a pas de conjoint survivant
                //     mais il y a des enfants survivants
                // NU-PROPRIETE
                // la nue-propriété du défunt est transmises aux enfants héritiers
                try? bareOwners.replace(thisOwner: decedentName, with: chidrenNames)
                // USUFRUIT
                // l'usufruit rejoint la nue-propriété cad que les nues-propriétaires
                // deviennent PP et le démembrement disparaît
                isDismembered  = false
                fullOwners     = bareOwners
                usufructOwners = [ ]
                bareOwners     = [ ]
            } // (3) sinon on ne change rien car il n'y a aucun héritier
            
        } else {
            // (B) le bien n'est pas démembré
            // est-ce que le défunt fait partie des co-propriétaires ?
            if hasAFullOwner(named: decedentName) {
                // (1) le défunt fait partie des co-propriétaires
                // on transfert sa part de propriété aux héritiers
                if let spouseName = spouseName {
                    // (a) il y a un conjoint survivant
                    transferFullOwnership(of                 : decedentName,
                                          toSpouse           : spouseName,
                                          toChildren         : chidrenNames,
                                          spouseFiscalOption : spouseFiscalOption)
                    
                } else if let chidrenNames = chidrenNames {
                    // (b) il n'y a pas de conjoint survivant
                    // mais il y a des enfants survivants
                    try? fullOwners.replace(thisOwner: decedentName, with: chidrenNames)
                }
            } // (2) sinon on ne change rien
        }
        guard isValid else {
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Retourne true si la personne est un des usufruitiers du bien
    /// - Parameter name: nom de la personne
    public func hasAnUsufructOwner(named name: String) -> Bool {
        isDismembered && usufructOwners.contains(where: { $0.name == name })
    }
    
    /// Retourne true si la personne est un des nupropriétaires du bien
    /// - Parameter name: nom de la personne
    public func hasABareOwner(named name: String) -> Bool {
        isDismembered && bareOwners.contains(where: { $0.name == name })
    }
    
    /// Retourne true si la personne est un des détenteurs du bien en pleine propriété
    /// - Parameter name: nom de la personne
    public func hasAFullOwner(named name: String) -> Bool {
        !isDismembered && fullOwners.contains(where: { $0.name == name })
    }
    
    /// Retourne true si la personne est le seul détenteur du bien en pleine propriété
    /// - Parameter name: nom de la personne
    public func hasAUniqueFullOwner(named name: String) -> Bool {
        !isDismembered && fullOwners.contains(where: { $0.name == name })
            && fullOwners.count == 1
    }
    
    /// Retourne true si la personne perçoit des revenus du bien
    /// - Parameter name: nom de la personne
    public func providesRevenue(to name: String) -> Bool {
        hasAFullOwner(named: name) || hasAnUsufructOwner(named: name)
    }
}

// MARK: - Extensions

extension Ownership: CustomStringConvertible {
    public var description: String {
        let header = """
         - Valide:   \(isValid.frenchString)
         - Démembré: \(isDismembered.frenchString)

        """
        let pp =
            !isDismembered ? " - Plein Propriétaires:\n    \(fullOwners.description)" : ""
        let uf =
            isDismembered ? " - Usufruitiers:\n    \(usufructOwners.description) \n" : ""
        let np =
            isDismembered ? " - Nu-Propriétaires:\n    \(bareOwners.description)" : ""
        return header + pp + uf + np
    }
}

extension Ownership: Codable {
    
    // MARK: - Nested Types
    
    enum CodingKeys: String, CodingKey {
        case fullOwners     = "plein_propriétaires"
        case bareOwners     = "nue_propriétaires"
        case usufructOwners = "usufruitiers"
        case isDismembered  = "est_démembré"
    }
}

extension Ownership: Equatable {
    public static func == (lhs: Ownership, rhs: Ownership) -> Bool {
        lhs.isDismembered  == rhs.isDismembered &&
            lhs.fullOwners     == rhs.fullOwners &&
            lhs.bareOwners     == rhs.bareOwners &&
            lhs.usufructOwners == rhs.usufructOwners &&
            lhs.isValid        == rhs.isValid
    }
}
