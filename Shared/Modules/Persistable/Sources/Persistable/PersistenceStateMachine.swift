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
    case load
    case modify
    case save
}

public enum PersistenceState: String {
    case created  = "Créé"
    case synced   = "Synchronisé"
    case modified = "Modifié"
}

public typealias PersistenceTransition   = Transition<PersistenceState, PersistenceEvent>

public typealias PersistenceStateMachine = StateMachine<PersistenceState, PersistenceEvent>
extension PersistenceStateMachine {
    public convenience init() {
        self.init(initialState: .created)
        
        // initialiser la StateMachine
        let transition1 = PersistenceTransition(with : .load,
                                                from : .created,
                                                to   : .synced)
        self.add(transition: transition1)
        let transition2 = PersistenceTransition(with : .modify,
                                                from : .synced,
                                                to   : .modified)
        self.add(transition: transition2)
        let transition3 = PersistenceTransition(with : .save,
                                                from : .modified,
                                                to   : .synced)
        self.add(transition: transition3)
        #if DEBUG
        self.enableLogging = true
        #endif
    }
}
