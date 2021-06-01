//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 01/06/2021.
//

import Foundation

public protocol Persistable {

    // MARK: - Properties

    var persistenceSM    : PersistenceStateMachine { get set }
    var persistenceState : PersistenceState { get }

}

public extension Persistable {
    var persistenceState: PersistenceState {
        persistenceSM.currentState
    }

}
