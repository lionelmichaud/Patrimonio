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
    /// - Warning:
    ///   - Le cas du capital démembrée et le défunt est nue-propriétaire n'est pas traité
    ///   - Le cas du capital co-détenu en PP par plusieurs personnes n'est pas traité
    ///   - le cas de plusieurs usufruitiers bénéficiaires n'est pas traité
    ///   - Le cas de parts non égales entre nue-propriétaires n'est pas traité
    ///
    /// - Throws:
    ///   - `OwnershipError.invalidOwnership`: le ownership avant ou après n'est pas valide
    public mutating func transferLifeInsurance(of decedentName    : String,
                                               accordingTo clause : LifeInsuranceClause) throws {
        guard isValid else {
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le capital de l'assurane vie est démembré
            transferDismemberedLifeInsurance(of: decedentName, accordingTo: clause)
            
        } else {
            // (B) le capital de l'assurance vie n'est pas démembré
            transferUnDismemberedLifeInsurance(of: decedentName, accordingTo: clause)
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
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiare de l'assurance vie
    public mutating func transferDismemberedLifeInsurance(of decedentName    : String,
                                                          accordingTo clause : LifeInsuranceClause) {
        // (A) le capital de l'assurane vie est démembré
        if hasAnUsufructOwner(named: decedentName) {
            // (1) le défunt est usufruitier
            // l'usufruit rejoint la nue-propriété
            transfertLifeInsuranceUsufruct()
            
        } else if hasABareOwner(named: decedentName) {
            // (2) le défunt est un nue-propriétaire
            // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
            customLogOwnership.log(level: .fault, "transferLifeInsuranceOfDecedent: cas non traité (capital démembré et le défunt est nue-propriétaire)")
            fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital démembré et le défunt est nue-propriétaire)")
            
        } else {
            // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien
            return
        }
    }
    
    /// Transférer la NP et l'UF  d'une assurance vie NON DEMEMBRÉE d'un défunt nommé `decedentName`
    /// aux donataires selon la `clause` bénéficiaire
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiare de l'assurance vie
    public mutating func transferUnDismemberedLifeInsurance(of decedentName    : String,
                                                            accordingTo clause : LifeInsuranceClause) {
        // (B) le capital de l'assurance vie n'est pas démembré
        // le défunt est-il un des PP propriétaires du capital de l'assurance vie ?
        if hasAFullOwner(named: decedentName) {
            // (1) le défunt est un des PP propriétaires du capital de l'assurance vie
            if fullOwners.count == 1 {
                // (a) le défunt est le seul PP de l'assurance vie
                if clause.isDismembered {
                    // (1) la clause bénéficiaire de l'assurane vie est démembrée
                    // Transférer l'usufruit et la nue-prorpiété de l'assurance vie séparement
                    transferUnDismemberedLifeInsToUsufructAndBareOwners(clause: clause)
                    
                } else {
                    // (2) la clause bénéficiaire de l'assurane vie n'est pas démembrée
                    // transférer le bien en PP aux donataires désignés dans la clause bénéficiaire
                    transferUnDismemberedLifeInsFullOwnership(clause: clause)
                }
                
            } else {
                // (b)
                // TODO: - traiter le cas où le défunt n'est pas le seul PP
                customLogOwnership.log(level: .fault, "transferLifeInsuranceOfDecedent: cas non traité (capital co-détenu en PP par plusieurs personnes)")
                fatalError("transferLifeInsuranceOfDecedent: cas non traité (capital co-détenu en PP par plusieurs personnes)")
            }
        } else {
            // (2) sinon on ne fait rien
            return
        }
    }
    
    /// Transférer l'usufruit lorqu'il rejoint la nue-propriété
    mutating func transfertLifeInsuranceUsufruct() {
        guard bareOwners.isNotEmpty else {
            customLogOwnership.log(level: .fault, "transfertLifeInsuranceUsufruct: Aucun nue-propriétaire à qui transmettre l'usufruit de l'assurance vie")
            fatalError("transfertLifeInsuranceUsufruct: Aucun nue-propriétaire à qui transmettre l'usufruit de l'assurance vie")
        }
        
        isDismembered = false
        fullOwners = []
        // chaque nue-propriétaire devient PP de sa propre part
        bareOwners.forEach {bareOwner in
            fullOwners.append(Owner(name: bareOwner.name, fraction: bareOwner.fraction))
        }
        bareOwners     = []
        usufructOwners = []
    }
    
    /// Transférer l'usufruit et la nue-prorpiété de l'assurance vie NON DEMEMBRÉE
    /// séparement aux bénéficiaires selon la `clause` bénéficiaire
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Warning:
    ///   - A n'utiliser que si le capital n'est pas démembrée
    ///   - A n'utiliser que si la `clause` est démembrée
    ///   - le cas de plusieurs usufruitiers bénéficiaires n'est pas traité
    ///   - le cas de parts non égales entre nue-propriétaires bénéficiaires n'est pas traité
    public mutating func transferUnDismemberedLifeInsToUsufructAndBareOwners(clause: LifeInsuranceClause) {
        guard !isDismembered else {
            customLogOwnership.log(level: .fault, "transferUnDismemberedLifeInsToUsufructAndBareOwners: L'assurance vie est démembrée")
            fatalError("transferUnDismemberedLifeInsToUsufructAndBareOwners: L'assurance vie est démembrée")
        }
        guard clause.bareRecipients.isNotEmpty else {
            fatalError("transferUnDismemberedLifeInsToUsufructAndBareOwners: Aucun nue-propriétaire désigné dans la clause bénéficiaire démembrée de l'assurance vie")
        }
        guard clause.usufructRecipient.isNotEmpty else {
            fatalError("transferUnDismemberedLifeInsToUsufructAndBareOwners: Aucun usufruitier désigné dans la clause bénéficiaire démembrée de l'assurance vie")
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
    }
    
    /// Transférer la PP de l'assurance vie NON DEMEMBRÉE aux donataires désignés
    /// dans la `clause` bénéficiaire
    ///
    /// - Warning:
    ///   - A n'utiliser que si le capital n'est pas démembrée
    ///   - A n'utiliser que si la `clause` n'est pas démembrée
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    public mutating func transferUnDismemberedLifeInsFullOwnership(clause: LifeInsuranceClause) {
        guard !isDismembered else {
            customLogOwnership.log(level: .fault, "transferUnDismemberedLifeInsFullOwnership: L'assurance vie est démembrée")
            fatalError("transferUnDismemberedLifeInsFullOwnership: L'assurance vie est démembrée")
        }
        guard clause.fullRecipients.isNotEmpty else {
            customLogOwnership.log(level: .fault, "Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
            fatalError("Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
        }
        
        self.isDismembered  = false
        self.fullOwners     = clause.fullRecipients
        self.bareOwners     = []
        self.usufructOwners = []
    }
}
