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

// MARK: - Société Civile Immobilière (SCI)
struct SCI {
    
    // MARK: - Properties

    var name        : String
    var note        : String
    var scpis       : ScpiArray
    var bankAccount : Double
    var isModified      : Bool {
        return scpis.persistenceState == .modified
    }
    // MARK: - Initializers
    
    /// Initialiser à vide
    init() {
        self.name        = ""
        self.note        = ""
        self.bankAccount = 0
        self.scpis       = ScpiArray()
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameter folder: dossier où se trouve le fichier JSON à utiliser
    internal init(fromFolder folder      : Folder,
                  name                   : String,
                  note                   : String,
                  with personAgeProvider : PersonAgeProvider?) throws {
        self.name  = name
        self.note  = note
        try self.scpis = ScpiArray(fileNamePrefix : "SCI_",
                                   fromFolder     : folder,
                                   with           : personAgeProvider)
        self.bankAccount = 0
    }
    
    // MARK: - Methods

    func saveAsJSON(toFolder folder: Folder) throws {
        try scpis.saveAsJSON(toFolder: folder)
    }
    
    /// Calls the given closure on each element in the sequence in the same order as a for-in loop
    func forEachOwnable(_ body: (Ownable) throws -> Void) rethrows {
        try scpis.items.forEach(body)
    }
    
    /// Transférer la propriété d'un bien d'un défunt vers ses héritiers en fonction de l'option
    ///  fiscale du conjoint survivant éventuel
    /// - Parameters:
    ///   - decedentName: défunt
    ///   - chidrenNames: noms des enfants héritiers survivant éventuels
    ///   - spouseName: nom du conjoint survivant éventuel
    ///   - spouseFiscalOption: option fiscale du conjoint survivant éventuel
    mutating func transferOwnershipOf(decedentName       : String,
                                      chidrenNames       : [String]?,
                                      spouseName         : String?,
                                      spouseFiscalOption : InheritanceFiscalOption?,
                                      atEndOf year       : Int) {
        for idx in scpis.items.range where scpis.items[idx].value(atEndOf: year) > 0 {
            try! scpis.items[idx].ownership.transferOwnershipOf(
                decedentName       : decedentName,
                chidrenNames       : chidrenNames,
                spouseName         : spouseName,
                spouseFiscalOption : spouseFiscalOption)
        }
    }
}

extension SCI: CustomStringConvertible {
    var description: String {
        """
        SCI: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        \(scpis.description.withPrefixedSplittedLines("  "))
        """
    }
}
