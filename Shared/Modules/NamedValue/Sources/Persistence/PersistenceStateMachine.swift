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
