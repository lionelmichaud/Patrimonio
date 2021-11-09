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
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - clause: la clause bénéficiaire de l'assurance vie
    ///
    /// - Note:
    ///   - le capital peut être démembré
    ///   -  la clause bénéficiare peut aussi être démembrée
    ///
    /// - Warning: Cas non traité:
    ///   - Capital démembré
    ///     - et le défunt est Nue-Propriétaire
    ///     - ou n'est pas le seul Usufruitier
    ///   - Capital non démembré
    ///     - et le défunt est un des PP du capital de l'assurance vie
    ///     - et la clause bénéficiaire de l'assurane vie est démembrée
    ///     - et le défunt n'est pas le seul PP
    ///   - Capital non démembré
    ///     - et la clause bénéficiaire de l'assurane vie est démembrée
    ///     - et parts non égales entre nue-propriétaires désignés dans la clause bénéficiaire
    ///
    /// - Throws:
    ///   - `ClauseError.invalidClause`
    ///   - `OwnershipError.invalidOwnership`
    ///   - `OwnershipError.tryingToTransferAssetWithManyFullOwnerAndDismemberedClause`
    ///   - `OwnershipError.tryingToTransferAssetWithDecedentAsBareOwner`
    ///   - `OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners`
    ///   - `OwnershipError.tryingToTransferAssetWithNoBareOwner`
    ///
    public mutating func transferLifeInsurance(of decedentName    : String,
                                               spouseName         : String?,
                                               childrenName       : [String]?,
                                               accordingTo clause : inout LifeInsuranceClause,
                                               verbose            : Bool = false) throws {
        guard isValid else {
            let invalid = self
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide\n\(invalid, privacy: .public)")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le capital de l'assurane vie est démembré
            try transferDismemberedLifeInsurance(
                of      : decedentName,
                verbose : verbose)
            
        } else {
            // (B) le capital de l'assurance vie n'est pas démembré
            try transferUndismemberedLifeInsurance(
                of           : decedentName,
                spouseName   : spouseName,
                childrenName : childrenName,
                accordingTo  : &clause,
                verbose      : verbose)
        }
        
        guard isValid else {
            let invalid = self
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide\n\(invalid, privacy: .public)")
            throw OwnershipError.invalidOwnership
        }
    }
    
    // MARK: - Assurance Vie DEMEMEBRÉE
    
    /// Transférer la NP et l'UF  d'une assurance vie DEMEMBRÉE d'un défunt nommé `decedentName`
    /// aux donataires selon la `clause` bénéficiaire
    ///
    /// - Warning: Cas non traité:
    ///   - le défunt est un un nue-propriétaire
    ///   - le défunt n'est pas le seul Usufruitier
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - clause: la clause bénéficiaire de l'assurance vie
    ///
    /// - Throws:
    ///   - OwnershipError.tryingToTransferAssetWithDecedentAsBareOwner
    ///   - OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners
    ///   - OwnershipError.tryingToTransferAssetWithNoBareOwner
    ///
    mutating func transferDismemberedLifeInsurance
    (of decedentName : String,
     verbose         : Bool = false) throws {
        // (A) le capital de l'assurane vie est démembré
        let isUsufructOwner = hasAnUsufructOwner(named: decedentName)
        let isBareOwner     = hasABareOwner(named: decedentName)
        
        switch (isUsufructOwner, isBareOwner) {
            case (true, false):
                // (1) le défunt est UF et pas NP
                // l'usufruit rejoint la nue-propriété
                try transfertDismemberedLifeInsuranceUsufruct(of: decedentName, verbose: verbose)
                
            case (_, true):
                // (2) le défunt est un NP
                // TODO: - traiter le cas où le capital de l'assurance vie est démembré et le défunt est nue-propriétaire
                let invalid = self
                customLogOwnership.log(level: .error,
                                       "transferDismemberedLifeInsurance: \(OwnershipError.tryingToTransferAssetWithDecedentAsBareOwner.rawValue)\n\(invalid, privacy: .public)")
                throw OwnershipError.tryingToTransferAssetWithDecedentAsBareOwner
                
            case (false, false):
                // (3) le défunt n'est ni usufruitier ni nue-propriétaire => on ne fait rien
                break
        }
    }
    
    /// Transférer l'usufruit de l'assurance vie lorqu'il rejoint la nue-propriété
    ///
    /// Pré-conditions
    ///    - Le capital est démembré au jour de la succession
    ///    - Le défunt est Usufruitier
    ///
    /// - Warning: Cas non traité:
    ///   - le défunt n'est pas le seul Usufruitier
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///
    /// - Throws:
    ///   - OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners
    ///   - OwnershipError.tryingToTransferAssetWithNoBareOwner
    ///
    fileprivate mutating func transfertDismemberedLifeInsuranceUsufruct(of decedentName : String,
                                                                        verbose         : Bool = false) throws {
        guard hasAUniqueUsufructOwner(named: decedentName) else {
            // TODO: - Gérer correctement les transferts de propriété des biens indivis et démembrés
            let invalid = self
            customLogOwnership.log(level: .error,
                                   "transfertDismemberedLifeInsuranceUsufruct: \(OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners.rawValue)\n\(invalid, privacy: .public)")
            throw OwnershipError.tryingToTransferAssetWithSeveralUsufructOwners
        }
        
        guard bareOwners.isNotEmpty else {
            let invalid = self
            customLogOwnership.log(level: .fault,
                                   "transfertDismemberedLifeInsuranceUsufruct: \(OwnershipError.tryingToTransferAssetWithNoBareOwner.rawValue)\n\(invalid, privacy: .public)")
            throw OwnershipError.tryingToTransferAssetWithNoBareOwner
        }
        
        // chaque nue-propriétaire devient PP de sa propre part
        isDismembered  = false
        fullOwners     = bareOwners
        bareOwners     = []
        usufructOwners = []

        groupShares()

        guard isValid else {
            let invalid = self
            customLogOwnership.log(level: .error,
                                   "transfertDismemberedLifeInsuranceUsufruct: \(OwnershipError.invalidOwnership.rawValue)\n\(invalid, privacy: .public)")
            throw OwnershipError.invalidOwnership
        }
    }
    
    // MARK: - Assurance Vie NON DEMEMEBRÉE

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
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - clause: la clause bénéficiaire de l'assurance vie
    ///
    /// - Throws:
    ///   - ClauseError.invalidClause
    ///   - OwnershipError.invalidOwnership
    ///   - OwnershipError.tryingToTransferAssetWithManyFullOwnerAndDismemberedClause
    ///
    public mutating func transferUndismemberedLifeInsurance
    (of decedentName    : String,
     spouseName         : String?,
     childrenName       : [String]?,
     accordingTo clause : inout LifeInsuranceClause,
     verbose            : Bool = false) throws {
        // (B) le capital de l'assurance vie n'est pas démembré
        // le défunt est-il un des PP propriétaires du capital de l'assurance vie ?
        guard !isDismembered && hasAFullOwner(named: decedentName) else {
            // (b) le défunt n'est pas un des PP propriétaires du capital de l'assurance vie
            return
        }
        
        if let ownerIdx = fullOwners.firstIndex(where: { decedentName == $0.name }) {
            // RECALCUL DES PARTS DES AUTRES PP
            // part de PP à éliminer care les capitaux décès correspondant ont été retirés
            let ownerShare = fullOwners[ownerIdx].fraction
            // retirer le défunt de la liste des PP
            fullOwners.remove(at: ownerIdx)
            // recalculer la part des autres PP
            let othersShare = 100.0 - ownerShare
            for idx in fullOwners.indices {
                fullOwners[idx].fraction = fullOwners[idx].fraction / othersShare * 100.0
            }
            groupShares()
            
            // MODIFICATION DE LA CLAUSE
            // le conjoint survivant fait-il partie des PP ?
            if fullOwners.contains(where: { spouseName == $0.name }) {
                if verbose {
                    print(
                        """
                        >> Transfert assurance vie détenue en PP:
                             Ownership après:
                                \(String(describing: self))
                           Modification de la clause:
                             Clause avant:
                                \(String(describing: clause))

                        """)
                }
                // la part détenue par le conjoint survivant sera donnée aux enfants par part égales
                // il faut mofifier la clause pour que sa part soit données aux enfants à son décès
                clause.isOptional = false
                clause.fullRecipients = []
                // redistribuer sa part aux enfants
                childrenName?.forEach { childName in
                    clause.fullRecipients.append(Owner(name     : childName,
                                                       fraction : 100.0 / childrenName!.count.double()))
                }
                if verbose {
                    print(
                        """
                             Clause après:
                                \(String(describing: clause))
                        """)
                }
                guard clause.isValid else {
                    let invalid = clause
                    let cause = clause.invalidityCause ?? ""
                    customLogOwnership.log(level: .error,
                                           "\(ClauseError.invalidClause.rawValue)\n\(invalid, privacy: .public)\n\(cause, privacy: .public)")
                    throw ClauseError.invalidClause
                }
            }
            
            guard isValid else {
                let invalid = self
                customLogOwnership.log(level: .error,
                                       "\(OwnershipError.invalidOwnership.rawValue)\n\(invalid, privacy: .public)")
                throw OwnershipError.invalidOwnership
            }
        }
    }
    
    /// Transférer l'usufruit et la nue-prorpiété de l'assurance vie NON DEMEMBRÉE
    /// séparement aux bénéficiaires selon la `clause` bénéficiaire
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Note:
    ///   - A n'utiliser que si le capital n'est PAS démembrée
    ///   - A n'utiliser que si la `clause` EST démembrée
    ///
    /// - Warning: Cas non traités:
    ///   - Parts non égales entre nue-propriétaires bénéficiaires
    ///
    /// - Throws:
    ///   - OwnershipError.invalidOwnership
    ///
//    fileprivate mutating func transferUndismemberedLifeInsToUsufructAndBareOwners
//    (accordingTo clause : LifeInsuranceClause,
//     verbose            : Bool = false) throws {
//        guard !isDismembered else {
//            customLogOwnership.log(level: .fault, "transferUndismemberedLifeInsToUsufructAndBareOwners: L'assurance vie est démembrée")
//            fatalError("transferUndismemberedLifeInsToUsufructAndBareOwners: L'assurance vie est démembrée")
//        }
//        guard clause.isDismembered else {
//            customLogOwnership.log(level: .fault, "La clause bénéficiaire de l'assurance vie n'est pas démembrée")
//            fatalError("La clause bénéficiaire de l'assurance vie n'est pas démembrée")
//        }
//        guard clause.usufructRecipient.isNotEmpty else {
//            customLogOwnership.log(level: .fault, "Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
//            fatalError("Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
//        }
//
//        isDismembered = true
//        self.fullOwners = []
//        // Il ne peut y avoir qu'un seul usufruitier (limite du Model)
//        self.usufructOwners = [Owner(name     : clause.usufructRecipient,
//                                     fraction : 100)]
//
//        // TODO: - traiter le cas des parts non égales chez les NP de la clause bénéficiaire
//        // répartition des parts de NP entre bénéficiaires en NP
//        let nbOfRecipients = clause.bareRecipients.count
//        let share          = 100.0 / nbOfRecipients.double()
//
//        self.bareOwners = []
//        // plusieurs nue-propriétaires possible
//        clause.bareRecipients.forEach { recipient in
//            self.bareOwners.append(Owner(name: recipient, fraction: share))
//        }
//        groupShares()
//
//        guard isValid else {
//            let invalid = self
//            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide \(invalid, privacy: .public)")
//            throw OwnershipError.invalidOwnership
//        }
//    }
    
    /// Transférer la PP de l'assurance vie NON DEMEMBRÉE aux donataires désignés
    /// dans la `clause` bénéficiaire
    ///
    /// - Warning: le capital du défunt doit avoir été retiré au préalable
    ///
    /// - Note:
    ///   - A n'utiliser que si le capital n'est PAS démembrée
    ///   - A n'utiliser que si la `clause` n'est PAS démembrée
    ///
    /// - Parameters:
    ///   - clause: la clause bénéficiare de l'assurance vie
    ///
    /// - Throws:
    ///   - ClauseError.invalidClause
    ///   - OwnershipError.invalidOwnership
    ///
//    mutating func transferUndismemberedLifeInsFullOwnership
//    (of decedentName    : String,
//     spouseName         : String?,
//     childrenName       : [String]?,
//     accordingTo clause : inout LifeInsuranceClause,
//     verbose            : Bool = false) throws {
//        guard !isDismembered else {
//            customLogOwnership.log(level: .fault, "L'assurance vie est démembrée")
//            fatalError("L'assurance vie est démembrée")
//        }
//        guard clause.fullRecipients.isNotEmpty else {
//            customLogOwnership.log(level: .fault,
//                                   "Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
//            fatalError("Aucun bénéficiaire dans la clause bénéficiaire de l'assurance vie")
//        }
//
//        if let ownerIdx = fullOwners.firstIndex(where: { decedentName == $0.name }) {
//            // RECALCUL DES PARTS DES AUTRES PP
//            // part de PP à éliminer care les capitaux décès correspondant ont été retirés
//            let ownerShare = fullOwners[ownerIdx].fraction
//            // retirer le défunt de la liste des PP
//            fullOwners.remove(at: ownerIdx)
//            // recalculer la part des autres PP
//            let othersShare = 100.0 - ownerShare
//            for idx in fullOwners.indices {
//                fullOwners[idx].fraction = fullOwners[idx].fraction / othersShare * 100.0
//            }
//            groupShares()
//
//            // MODIFICATION DE LA CLAUSE
//            // le conjoint survivant fait-il partie des PP ?
//            if fullOwners.contains(where: { spouseName == $0.name }) {
//                if verbose {
//                    print(
//                        """
//                        >> Transfert assurance vie détenue en PP:
//                             Ownership après:
//                                \(String(describing: self))
//                           Modification de la clause:
//                             Clause avant:
//                                \(String(describing: clause))
//
//                        """)
//                }
//                // la part détenue par le conjoint survivant sera donnée aux enfants par part égales
//                // il faut mofifier la clause pour que sa part soit données aux enfants à son décès
//                clause.isOptional = false
//                clause.fullRecipients = []
//                // redistribuer sa part aux enfants
//                childrenName?.forEach { childName in
//                    clause.fullRecipients.append(Owner(name     : childName,
//                                                       fraction : 100.0 / childrenName!.count.double()))
//                }
//                if verbose {
//                    print(
//                        """
//                             Clause après:
//                                \(String(describing: clause))
//                        """)
//                }
//                guard clause.isValid else {
//                    let invalid = clause
//                    let cause = clause.invalidityCause ?? ""
//                    customLogOwnership.log(level: .error,
//                                           "\(ClauseError.invalidClause.rawValue)\n\(invalid, privacy: .public)\n\(cause, privacy: .public)")
//                    throw ClauseError.invalidClause
//                }
//            }
//
//            guard isValid else {
//                let invalid = self
//                customLogOwnership.log(level: .error,
//                                       "\(OwnershipError.invalidOwnership.rawValue)\n\(invalid, privacy: .public)")
//                throw OwnershipError.invalidOwnership
//            }
//        }
//    }
}
