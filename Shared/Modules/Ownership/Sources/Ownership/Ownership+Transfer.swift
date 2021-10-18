//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 18/10/2021.
//

import Foundation
import FiscalModel

extension Ownership {
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    /// - Warning: Ne fonctionne pas pour un bien avec plusieurs Usufruitiers
    /// - Throws:
    ///   - OwnershipError.invalidOwnership: le ownership avant ou après n'est pas valide
    ///   - OwnersError.ownerDoesNotExist; OwnersError.noNewOwners
    ///   - bien avec plusieurs Usufruitiers: OwnershipError.tryingToTransferAssetithSeveralUsufructOwners
    public mutating func transferOwnershipOf
    (decedentName       : String,
     chidrenNames       : [String]?,
     spouseName         : String?,
     spouseFiscalOption : InheritanceFiscalOption?) throws {
        guard isValid else {
            customLogOwnership.log(level: .error, "Tentative de transfert de propriété avec 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
        
        if isDismembered {
            // (A) le bien est démembré
            try transferDismemberedOwnershipOf(decedentName       : decedentName,
                                               chidrenNames       : chidrenNames,
                                               spouseName         : spouseName,
                                               spouseFiscalOption : spouseFiscalOption)
            
        } else {
            // (B) le bien n'est pas démembré
            try transferUndismemberedOwnershipOf(decedentName       : decedentName,
                                                 chidrenNames       : chidrenNames,
                                                 spouseName         : spouseName,
                                                 spouseFiscalOption : spouseFiscalOption)
        }
        
        guard isValid else {
            customLogOwnership.log(level: .error, "'transferOwnershipOf' a généré un 'ownership' invalide")
            throw OwnershipError.invalidOwnership
        }
    }
    
    /// Transférer la propriété d'un bien DÉMEMBRÉ d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    /// - Warning: Ne fonctionne pas pour un bien avec plusieurs Usufruitiers
    /// - Throws:
    ///   - OwnersError.ownerDoesNotExist; OwnersError.noNewOwners
    ///   - bien avec plusieurs Usufruitiers: OwnershipError.tryingToTransferAssetithSeveralUsufructOwners
    mutating func transferDismemberedOwnershipOf
    (decedentName       : String,
     chidrenNames       : [String]?,
     spouseName         : String?,
     spouseFiscalOption : InheritanceFiscalOption?) throws {
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
                    try transferUsufructAndBareOwnership(of                 : decedentName,
                                                          toSpouse           : spouseName,
                                                          toChildren         : chidrenNames,
                                                          spouseFiscalOption : spouseFiscalOption)
                    
                } else {
                    // (2) le défunt était seulement usufruitier
                    // le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
                    // cad que les nues-propriétaires deviennent PP
                    try transferUsufruct(of         : decedentName,
                                          toChildren : chidrenNames)
                    
                }
            } else if bareOwners.contains(ownerName: decedentName) {
                // (b) le défunt était seulement nue-propriétaire
                // NUE-PROPRIETE
                // retirer le défunt de la liste des nue-propriétaires
                // et répartir sa part sur ses héritiers selon l'option retenue par le conjoint survivant
                // TODO: - Ca ne marche pas comme ça: la NP rejoint l'UF en l'absence d'héritier du défunt
                try transferBareOwnership(of                 : decedentName,
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
    }
    
    /// Transférer la propriété d'un bien NON DÉMEMBRÉ d'un défunt vers ses héritiers en fonction de l'option
    /// fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    /// - Throws:
    ///   - OwnersError.ownerDoesNotExist; OwnersError.noNewOwners
    mutating func transferUndismemberedOwnershipOf
    (decedentName       : String,
     chidrenNames       : [String]?,
     spouseName         : String?,
     spouseFiscalOption : InheritanceFiscalOption?) throws {
        // est-ce que le défunt fait partie des pleins co-propriétaires ?
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
                try fullOwners.replace(thisOwner: decedentName, with: chidrenNames)
            } // (c) il n'y a pas de conjoint ni d'enfants survivants: on ne change rien
        } // (2) sinon on ne change rien
    }
}
