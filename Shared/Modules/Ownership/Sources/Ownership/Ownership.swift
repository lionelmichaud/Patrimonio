//
//  Demembrement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 29/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
import Foundation
import os
import AppFoundation
import NamedValue
import FiscalModel

let customLogOwnership = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Ownership")

public typealias NameValueDico = [String : Double]
extension NameValueDico {
    init(from namedValueArray: NamedValueArray) {
        var dico = NameValueDico()
        namedValueArray.forEach {
            dico[$0.name] = $0.value
        }
        self = dico
    }
}

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
    case ifi                       = "Valeur fiscale IFI"
    case isf                       = "Valeur fiscale ISF"
    case legalSuccession           = "Valeur fiscale Succession Légale"
    case lifeInsuranceSuccession   = "Valeur fiscale Succession Assurance Vie"
    case lifeInsuranceTransmission = "Valeur transmise Succession Assurance Vie"
    case patrimoine                = "Valeur Patrimoniale"

    public var pickerString: String {
        return self.rawValue
    }
    
    public var displayString: String {
        switch self {
            case .ifi:
                return "Valeur fiscale IFI"
            case .isf:
                return "Valeur fiscale ISF"
            case .legalSuccession:
                return "Valeur fiscale Suc. Légale"
            case .lifeInsuranceSuccession:
                return "Valeur fiscale Suc. Ass. Vie"
            case .lifeInsuranceTransmission:
                return "Valeur transmise Suc. Ass. Vie"
            case .patrimoine:
                return "Valeur Patrimoniale"
        }

    }
}

// MARK: - La répartition des droits de propriété d'un bien entre personnes

public enum OwnershipError: String, Error {
    case tryingToDismemberAnUndismemberedAsset =
            "Tentative de calul des valeurs démembrées d'un bien non démembré"
    case tryingToTransferAssetWithNoBareOwner =
            "Tentative de transmission d'un bien ne possédant pas de NP"
    case invalidOwnership =
            "Ownership est invalid"
    case tryingToTransferAssetWithSeveralUsufructOwners =
            "Cas non traité: Tentative de transmission d'un bien possédant plusieurs UF"
    case tryingToTransferAssetWithDecedentAsBareOwner =
            "Cas non traité: Tentative de transmission d'un bien dont le défunt est NP"
    case tryingToTransferAssetWithManyFullOwnerAndDismemberedClause =
            "Cas non traité: Tentative de transmission d'une AV avec Clause démembrée et dont le défunt est PP parmi plusieurs"
}

// MARK: - Struct définissant les droits de propriété d'un bien

public struct Ownership {
    
    // MARK: - Static Properties
    
    // dependencies
    static var demembrementProviderP : DemembrementProviderP!
    
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
            // aucun propriétaire est autorisé
            return fullOwners.isvalid
        }
    }
    public var isOwnedBySomebody: Bool {
        if isDismembered {
            return usufructOwners.isNotEmpty
        } else {
            return fullOwners.isNotEmpty
        }
    }
    
    // MARK: - Initializers
    
    public init(ageOf: @escaping (_ name: String, _ year: Int) -> Int) {
        self.ageOf = ageOf
    }
    
    public init() { }
    
    // MARK: - Methods
    
    public mutating func setDelegateForAgeOf(delegate: ((_ name: String, _ year: Int) -> Int)?) {
        ageOf = delegate
    }
    
    /// Factoriser les parts des usufuitier et des nue-propriétaires si nécessaire
    public mutating func groupShares() {
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
    
    /// Retourne true si la personne est un des usufruitiers du bien
    /// - Parameter name: nom de la personne
    public func hasAnUsufructOwner(named name: String) -> Bool {
        isDismembered && usufructOwners.contains(where: { $0.name == name })
    }
    
    /// Retourne true si la personne est le seul détenteur de l'UF du bien
    /// - Parameter name: nom de la personne
    public func hasAUniqueUsufructOwner(named name: String) -> Bool {
        isDismembered && usufructOwners.contains(where: { $0.name == name })
            && usufructOwners.count == 1
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
            customLogOwnership.log(level: .error, "\(OwnershipError.tryingToDismemberAnUndismemberedAsset.rawValue)")
            throw OwnershipError.tryingToDismemberAnUndismemberedAsset
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
