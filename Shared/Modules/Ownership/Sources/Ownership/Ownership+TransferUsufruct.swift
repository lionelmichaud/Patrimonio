//
//  Ownership+TransferUsufruct.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 14/07/2021.
//

import Foundation
import FiscalModel

extension Ownership {
    /// Transférer l'usufruit du défunt aux nue-propriétaires
    /// - Note:
    ///   - le défunt était seulement usufruitier
    ///   - le défunt avait donné sa nue-propriété avant son décès, alors l'usufruit rejoint la nue-propriété
    ///   - cad que les nues-propriétaires deviennent PP
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - chidrenNames: les enfants héritiers survivants
    /// - Warning: Ne donne pas le bon résultat pour un bien indivis.
    mutating func transferUsufruct(of decedentName         : String,
                                   toChildren chidrenNames : [String]?) {
        // TODO: - Gérer correctement les transferts de propriété des biens indivis et démembrés
        if let chidrenNames = chidrenNames {
            //if let decedent = usufructOwners.owner(ownerName: decedentName) {
            // la part d'usufruit à transmettre
            //let usufructShare = decedent.fraction
            
            // l'UF rejoint la nue-propriété (enfants seulement)
            chidrenNames.forEach { childName in
                if let bareowner = bareOwners[childName] {
                    usufructOwners.append(Owner(name: bareowner.name,
                                                fraction: bareowner.fraction))
                }
            }
            
            // on supprime le défunt de la liste
            usufructOwners.removeAll(where: { $0.name == decedentName })
            
            // factoriser les parts des usufuitiers et des nue-propriétaires si nécessaire
            groupShares()
            //}
        }
    }
    
    /// Transférer la NP et UF  d'un copropriétaire d'un bien démembré à ses héritiers selon l'option retenue par le conjoint survivant
    /// - Note:
    ///  - le défunt était usufruitier et nue-propriétaire
    ///  - UF + NP sont transmis selon l'option du conjoint survivant comme une PP
    ///
    /// - Parameters:
    ///   - decedentName: le nom du défunt
    ///   - spouseName: le conjoint survivant
    ///   - chidrenNames: les enfants héritiers survivants
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferUsufructAndBareOwnership(of decedentName         : String,
                                                   toSpouse spouseName     : String,
                                                   toChildren chidrenNames : [String]?,
                                                   spouseFiscalOption      : InheritanceFiscalOption?) {
        if let chidrenNames = chidrenNames {
            // il y a des enfants héritiers
            // transmission NP + UF selon l'option fiscale du conjoint survivant
            guard let spouseFiscalOption = spouseFiscalOption else {
                fatalError("pas d'option fiscale passée en paramètre de transferOwnershipOf")
            }
            // l'UF du défunt rejoint la nue propriété des enfants qui la détiennent
            transferUsufruct(of         : decedentName,
                             toChildren : chidrenNames)
            // la NP est transmise aux enfants nue-propriétaires
            transferBareOwnership(of                 : decedentName,
                                  toSpouse           : spouseName,
                                  toChildren         : chidrenNames,
                                  spouseFiscalOption : spouseFiscalOption)
            
        } else {
            // il n'y pas d'enfant héritier mais un conjoint survivant
            // tout revient au conjoint survivant en PP
            // on transmet l'UF au conjoint survivant
            if let ownerIdx = usufructOwners.firstIndex(where: { decedentName == $0.name }) {
                // la part d'usufruit à transmettre
                let ownerShare = usufructOwners[ownerIdx].fraction
                usufructOwners.append(Owner(name: spouseName, fraction: ownerShare))
                // on supprime le défunt de la liste
                usufructOwners.remove(at: ownerIdx)
            }
            // on transmet la NP au conjoint survivant
            if let ownerIdx = bareOwners.firstIndex(where: { decedentName == $0.name }) {
                let ownerShare = bareOwners[ownerIdx].fraction
                // la part de nue-propriété à transmettre
                bareOwners.append(Owner(name: spouseName, fraction: ownerShare))
                // on supprime le défunt de la liste
                bareOwners.remove(at: ownerIdx)
            }
        }
        // factoriser les parts des usufuitiers et des nue-propriétaires si nécessaire
        groupShares()
    }
}
