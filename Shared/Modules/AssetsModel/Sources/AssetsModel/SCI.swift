//
//  SCI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel
import Files
import Ownership

// MARK: - Société Civile Immobilière (SCI)
public struct SCI {
    
    // MARK: - Properties
    
    public var name        : String
    public var note        : String
    public var scpis       : ScpiArray
    public var bankAccount : Double
    public var isModified  : Bool {
        return scpis.persistenceState == .modified
    }
    // MARK: - Initializers
    
    /// Initialiser à vide
    public init() {
        self.name        = ""
        self.note        = ""
        self.bankAccount = 0
        self.scpis       = ScpiArray()
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Throws: en cas d'échec de lecture des données
    /// - Note: personAgeProvider est utilisée pour injecter dans chaque actif un délégué personAgeProvider.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - name: nom de la SCI
    ///   - note: note associée à la SCI
    ///   - personAgeProvider: forunit l'age d'une personne à partir de son nom
    /// - Throws: en cas d'échec de lecture des données
    public init(fromFolder folder      : Folder,
                name                   : String,
                note                   : String,
                with personAgeProvider : PersonAgeProviderP?) throws {
        self.name  = name
        self.note  = note
        try self.scpis = ScpiArray(fileNamePrefix : "SCI_",
                                   fromFolder     : folder,
                                   with           : personAgeProvider)
        self.bankAccount = 0
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier du `bundle`
    /// - Note: Utilisé seulement pour les Tests
    /// - Note: personAgeProvider est utilisée pour injecter dans chaque actif un délégué personAgeProvider.ageOf
    ///         permettant de calculer les valeurs respectives des Usufruits et Nu-Propriétés
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    ///   - name: nom de la SCI
    ///   - note: note associée à la SCI
    ///   - personAgeProvider: forunit l'age d'une personne à partir de son nom
    /// - Throws: en cas d'échec de lecture des données
    public init(fromBundle bundle      : Bundle,
                fileNamePrefix         : String = "",
                name                   : String,
                note                   : String,
                with personAgeProvider : PersonAgeProviderP?) {
        self.name  = name
        self.note  = note
        self.scpis = ScpiArray(fromBundle     : bundle,
                               fileNamePrefix : fileNamePrefix + "SCI_",
                               with           : personAgeProvider)
        self.bankAccount = 0
    }
    
    // MARK: - Methods
    
    public func saveAsJSON(toFolder folder: Folder) throws {
        try scpis.saveAsJSON(toFolder: folder)
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    public func forEachOwnable(_ body: (OwnableP) throws -> Void) rethrows {
        try scpis.items.forEach(body)
    }
    
    public func forEachQuotableNameableValuable(_ body: (QuotableNameableValuableP) throws -> Void) rethrows {
        try scpis.items.forEach(body)
    }

    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    public mutating func transferOwnershipOf(decedentName       : String,
                                             chidrenNames       : [String]?,
                                             spouseName         : String?,
                                             spouseFiscalOption : InheritanceFiscalOption?,
                                             atEndOf year       : Int) {
        for idx in scpis.items.indices where scpis.items[idx].value(atEndOf: year) > 0 {
            try! scpis.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
    }
}

extension SCI: CustomStringConvertible {
    public var description: String {
        """
        SCI: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        \(scpis.description.withPrefixedSplittedLines("  "))
        """
    }
}
