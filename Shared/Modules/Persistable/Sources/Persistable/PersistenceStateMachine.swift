//
//  PersistenceStateMachine.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/05/2021.
//

import Foundation
import Stateful

// MARK: - State Machine de gestion de la persistence

public enum PersistenceEvent {
    case onLoad
    case onModify
    case onSave
}

public enum PersistenceState: String {
    case created  = "Créé"
    case synced   = "Synchronisé" // avec le dossier local
    case modified = "Modifié"
}

public typealias PersistenceTransition   = Transition<PersistenceState, PersistenceEvent>

public typealias PersistenceStateMachine = StateMachine<PersistenceState, PersistenceEvent>
extension PersistenceStateMachine {
    public convenience init() {
        self.init(initialState: .created)
        
        // initialiser la StateMachine
        let transition1 = PersistenceTransition(with : .onLoad,
                                                from : .created,
                                                to   : .synced)
        self.add(transition: transition1)
        let transition2 = PersistenceTransition(with : .onModify,
                                                from : .synced,
                                                to   : .modified)
        self.add(transition: transition2)
        let transition3 = PersistenceTransition(with : .onSave,
                                                from : .modified,
                                                to   : .synced)
        self.add(transition: transition3)
        #if DEBUG
        self.enableLogging = true
        #endif
    }
}
