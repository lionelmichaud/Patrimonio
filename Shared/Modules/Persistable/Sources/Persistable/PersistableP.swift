//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 01/06/2021.
//

import Foundation

public protocol PersistableP {

    // MARK: - Properties

    var persistenceSM    : PersistenceStateMachine { get set }
    var persistenceState : PersistenceState { get }
    var isModified       : Bool { get }
}

public extension PersistableP {
    var persistenceState: PersistenceState {
        persistenceSM.currentState
    }
    var isModified: Bool {
        persistenceSM.currentState == .modified
    }
}
