//
//  DossierViewModel.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/05/2021.
//

import Foundation
import AppFoundation
import Persistence

struct DossierViewModel {
    
    // MARK: - Properties
    
    var name: String
    var note: String
    
    // MARK: - Initializers

    init(from dossier: Dossier? = nil) {
        if let dossier = dossier {
            name = dossier.name
            note = dossier.note
        } else {
            name = Date.now.stringShortDate
            note = ""
        }
    }
    
    // MARK: - Methods

    func copyFromViewModel(original: Dossier) -> Dossier {
        var copy = original
        copy.name = name
        copy.note = note
        return copy
    }
    
    func isValid() -> Bool {
        name.isNotEmpty
    }
}
