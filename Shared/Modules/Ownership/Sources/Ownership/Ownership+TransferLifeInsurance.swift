//
//  Ownership+TransferLifeInsurance.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 17/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

extension Ownership {
    
    /// Transférer la NP et l'UF  d'une assurance vie d'un défunt nommé `decedentName`
    /// aux donataires selon la `clause` bénéficiaire
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Note:
    ///   - le capital peut être démembré
    ///   -  la clause bénéficiare peut aussi être démembrée
    ///
    /// - Warning: Cas non traité:
    ///   - Capital démembré
    ///     - et le défunt est nue-propriétaire
    ///   - Capital non démembré
    ///     - et le défunt est un des PP propriétaires du capital de l'assurance vie
    ///     - et la clause bénéficiaire de l'assurane vie est démembrée
    ///     - et le défunt n'est pas le seul PP
    ///   - Capital non démembré
    ///     - et la clause bénéficiaire de l'assurane vie est démembrée
    ///     - et parts non égales entre nue-propriétaires désignés dans la clause bénéficiaire
    ///
    /// - Throws:
    ///   - `OwnershipError.invalidOwnership`: le ownership avant ou après n'est pas valide
    public mutating func transferLifeInsurance(of decedentName    : String,
                                               spouseName         : String?,
                                               childrenName       : [String]?,
                                               accordingTo clause : inout LifeInsuranceClause) throws {
        guard isValid else {
            let invalid = self
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide \(invalid, privacy: .public)")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le capital de l'assurane vie est démembré
            try transferDismemberedLifeInsurance(of: decedentName,
                                             accordingTo: clause)
            
        } else {
            // (B) le capital de l'assurance vie n'est pas démembré
            try transferUndismemberedLifeInsurance(of           : decedentName,
                                               spouseName   : spouseName,
                                               childrenName : childrenName,
                                               accordingTo  : &clause)
        }
        groupShares()
        
        guard isValid else {
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Transférer la NP et l'UF  d'une assurance vie DEMEMBRÉE d'un défunt nommé `decedentName`
    /// aux donataires selon la `clause` bénéficiaire
    ///
    /// - Warning: Cas non traité:
    ///   - le défunt est un un nue-propriétaire
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiare de l'assurance vie
    mutating func transferDismemberedLifeInsurance
    (of decedentName    : String,
     accordingTo clause : LifeInsuranceClause) throws {
        // (A) le capital de l'assurane vie est démembré
        if hasAnUsufructOwner(named: decedentName) {
            // (1) le défunt est usufruitier
            // l'usufruit rejoint la nue-propriété
            try transfertDismemberedLifeInsuranceUsufruct()
            
        }
        if hasABareOwner(named: decedentName) {
            // (2) le défunt est un nue-propriétaire
            // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
            customLogOwnership.log(level: .fault, "transferLifeInsuranceOfDecedent: cas non traité (capital démembré et le défunt est nue-propriétaire)")
            fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital démembré et le défunt est nue-propriétaire)")
        }
        // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien
    }
    
    /// Transférer l'usufruit lorqu'il rejoint la nue-propriété
    mutating func transfertDismemberedLifeInsuranceUsufruct() throws {
        guard bareOwners.isNotEmpty else {
            customLogOwnership.log(level: .fault, "transfertLifeInsuranceUsufruct: Aucun nue-propriétaire à qui transmettre l'usufruit de l'assurance vie")
            fatalError("transfertLifeInsuranceUsufruct: Aucun nue-propriétaire à qui transmettre l'usufruit de l'assurance vie")
        }
        
        isDismembered = false
        // chaque nue-propriétaire devient PP de sa propre part
        fullOwners     = bareOwners
        bareOwners     = []
        usufructOwners = []

        guard isValid else {
            let invalid = self
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide \(invalid, privacy: .public)")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Transférer la NP et l'UF  d'une assurance vie NON DEMEMBRÉE d'un défunt nommé `decedentName`
    /// aux donataires selon la `clause` bénéficiaire.
    /// Dans le cas où la clause n'est pas démembrée et si le conjoint survivant fait partie des donataires,
    /// met à jour la clause bénéficiaire pour désigner les enfants comme bénéficiaires de la part héritée par le conjoint à son décès
    ///
    /// - Warning: Cas non traité:
    ///   - Le défunt est un des PP propriétaires du capital de l'assurance vie
    ///     - && la clause bénéficiaire de l'assurane vie est démembrée
    ///     - && le défunt n'est pas le seul PP
    ///   - Parts non égales entre nue-propriétaires bénéficiaires
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiare de l'assurance vie
    public mutating func transferUndismemberedLifeInsurance
    (of decedentName    : String,
     spouseName         : String?,
     childrenName       : [String]?,
     accordingTo clause : inout LifeInsuranceClause) throws {
        // (B) le capital de l'assurance vie n'est pas démembré
        // le défunt est-il un des PP propriétaires du capital de l'assurance vie ?
        if hasAFullOwner(named: decedentName) {
            // (1) le défunt est un des PP propriétaires du capital de l'assurance vie
            if clause.isDismembered {
                // (1) la clause bénéficiaire de l'assurane vie est démembrée
                if fullOwners.count == 1 {
                    // (a) le défunt est le seul PP de l'assurance vie
                    // Transférer l'usufruit et la nue-prorpiété de l'assurance vie séparement
                    try transferUndismemberedLifeInsToUsufructAndBareOwners(accordingTo: clause)
                } else {
                    // (b)
                    // TODO: - traiter le cas où le défunt n'est pas le seul PP
                    customLogOwnership.log(level: .fault, "transferUndismemberedLifeInsurance: cas non traité (capital co-détenu en PP par plusieurs personnes avec clause démembrée)")
                    fatalError("transferUndismemberedLifeInsurance: cas non traité (capital co-détenu en PP par plusieurs personnes avec clause démembrée)")
                }
                
            } else {
                // (2) la clause bénéficiaire de l'assurance vie n'est pas démembrée
                // transférer le bien en PP aux donataires désignés dans la clause bénéficiaire
                try transferUndismemberedLifeInsFullOwnership(of           : decedentName ,
                                                              spouseName   : spouseName,
                                                              childrenName : childrenName,
                                                              accordingTo  : &clause)
            }
            
        } else {
            // (2) sinon on ne fait rien
            return
        }
    }
    
    /// Transférer l'usufruit et la nue-prorpiété de l'assurance vie NON DEMEMBRÉE
    /// séparement aux bénéficiaires selon la `clause` bénéficiaire
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Note:
    ///   - A n'utiliser que si le capital n'est pas démembrée
    ///   - A n'utiliser que si la `clause` est démembrée
    ///
    /// - Warning: Cas non traités:
    ///   - Parts non égales entre nue-propriétaires bénéficiaires
    mutating func transferUndismemberedLifeInsToUsufructAndBareOwners
    (accordingTo clause: LifeInsuranceClause) throws {
        guard !isDismembered else {
            customLogOwnership.log(level: .fault, "transferUndismemberedLifeInsToUsufructAndBareOwners: L'assurance vie est démembrée")
            fatalError("transferUndismemberedLifeInsToUsufructAndBareOwners: L'assurance vie est démembrée")
        }
        guard clause.usufructRecipient.isNotEmpty else {
            customLogOwnership.log(level: .fault, "Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
            fatalError("Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
        }

        isDismembered = true
        self.fullOwners = []
        // un seul usufruitier
        self.usufructOwners = [Owner(name     : clause.usufructRecipient,
                                     fraction : 100)]
        
        // TODO: - traiter le cas des parts non égales chez les NP de la clause bénéficiaire
        // répartition des parts de NP entre bénéficiaires en NP
        let nbOfRecipients = clause.bareRecipients.count
        let share          = 100.0 / nbOfRecipients.double()
        
        self.bareOwners = []
        // plusieurs nue-propriétaires possible
        clause.bareRecipients.forEach { recipient in
            self.bareOwners.append(Owner(name: recipient, fraction: share))
        }

        guard isValid else {
            let invalid = self
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide \(invalid, privacy: .public)")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Transférer la PP de l'assurance vie NON DEMEMBRÉE aux donataires désignés
    /// dans la `clause` bénéficiaire
    ///
    /// - Note:
    ///   - A n'utiliser que si le capital n'est pas démembrée
    ///   - A n'utiliser que si la `clause` n'est pas démembrée
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    mutating func transferUndismemberedLifeInsFullOwnership
    (of decedentName    : String,
     spouseName         : String?,
     childrenName       : [String]?,
     accordingTo clause : inout LifeInsuranceClause) throws {
        guard !isDismembered else {
            customLogOwnership.log(level: .fault, "transferUndismemberedLifeInsFullOwnership: L'assurance vie est démembrée")
            fatalError("transferUndismemberedLifeInsFullOwnership: L'assurance vie est démembrée")
        }
        guard clause.fullRecipients.isNotEmpty else {
            customLogOwnership.log(level: .fault, "transferUndismemberedLifeInsFullOwnership: Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
            fatalError("transferUndismemberedLifeInsFullOwnership: Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
        }
        
        if let ownerIdx = fullOwners.firstIndex(where: { decedentName == $0.name }) {
            // part de PP à redistribuer selon la clause bénéficiaire
            let ownerShare = fullOwners[ownerIdx].fraction
            // retirer le défunt de la liste des PP
            fullOwners.remove(at: ownerIdx)
            // redistribuer selon la clause bénéficiaire
            clause.fullRecipients.forEach { recepient in
                fullOwners.append(Owner(name     : recepient.name,
                                        fraction : ownerShare * recepient.fraction / 100.0))
            }
            groupShares()
            print(">> Transfert assurance vie détenue en PP: \n Ownership avant\n\(String(describing: self))")
            print(" Clause avant\n\(String(describing: clause))")

            // le conjoint survivant fait-il partie des nouveaux PP ?
            if fullOwners.contains(where: { spouseName == $0.name }) {
                // la part détenue par le conjoint survivant sera donnée aux enfants par part égales
                // il faut mofifier la clause pour que sa part soit données aux enfants à son décès
                clause.isOptional = false
                clause.fullRecipients = []
                // redistribuer sa part aux enfants
                childrenName?.forEach { childName in
                        clause.fullRecipients.append(Owner(name     : childName,
                                                           fraction : 100.0 / childrenName!.count.double()))
                }

                guard clause.isValid else {
                    let invalid = clause
                    customLogOwnership.log(level: .error, "'transferUndismemberedLifeInsFullOwnership' a généré une 'clause' invalide \(invalid, privacy: .public)")
                    throw ClauseError.invalidClause
                }
            }
            
            guard isValid else {
                let invalid = self
                customLogOwnership.log(level: .error, "'transferUndismemberedLifeInsFullOwnership' a généré un 'ownership' invalide \(invalid, privacy: .public)")
                throw OwnershipError.invalidOwnership
            }
        }
    }
}
