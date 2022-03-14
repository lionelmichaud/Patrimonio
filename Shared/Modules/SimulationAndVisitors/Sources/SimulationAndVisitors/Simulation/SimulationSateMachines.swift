//
//  SimulationSateMachines.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/09/2021.
//

import Foundation
import Stateful

// MARK: - State Machine de l'état du Calcul de la Simulation

public enum SimulationEvent {
    /// L'utilisateur vient de lancer une simulation
    case onComputationTrigger
    /// Non utilisé, pour un usage futur
    case onComputationPause
    /// Les calculs de simulation viennent de se terminer
    case onComputationCompletion
    /// L'utilisateur vient de mofifier un paramètre de simulation
    case onComputationInputsModification
    /// Les résultats de simulation on été sauvegarder dans le répertoire local Document avec succès
    case onSaveSuccessfulCompletion
}

public enum SimulationComputationState: String {
    /// Quand les résultats de la dernière simulation ne sont plus valides car une donnée d'entrée a changée
    case invalid   = "Invalide"
    case computing = "Calcul en cours"
    case completed = "Terminée"
    case paused    = "En pause"
}

public typealias SimulationComputationTransition   = Transition<SimulationComputationState, SimulationEvent>

public typealias SimulationComputationStateMachine = StateMachine<SimulationComputationState, SimulationEvent>
extension SimulationComputationStateMachine {
    public convenience init() {
        self.init(initialState: .invalid)
        
        // initialiser la StateMachine
        let transition1 =
            SimulationComputationTransition(with : .onComputationTrigger,
                                            from : .invalid,
                                            to   : .computing)
        self.add(transition: transition1)
        
        let transition2 =
            SimulationComputationTransition(with : .onComputationCompletion,
                                            from : .computing,
                                            to   : .completed)
        self.add(transition: transition2)
        
        let transition3 =
            SimulationComputationTransition(with : .onComputationInputsModification,
                                            from : .completed,
                                            to   : .invalid)
        self.add(transition: transition3)
        
        let transition4 =
            SimulationComputationTransition(with : .onComputationTrigger,
                                            from : .completed,
                                            to   : .computing)
        self.add(transition: transition4)
        
        #if DEBUG
        self.enableLogging = true
        #endif
    }
}

// MARK: - State Machine de l'état de Sauvegarde de la Simulation

public enum SimulationPersistenceState: String {
    /// Quand les résultats de la dernière simulation ne sont plus valides car une donnée d'entrée a changée
    case invalid = "Invalide"
    /// Quand les résultats de la dernière simulation sont valides mais pas sauvegardés
    case savable = "Valide & Non sauvegardée"
    /// Quand les résultats de la dernière simulation sont valides et sauvegardés
    case saved   = "Sauvegardée"
}

public typealias SimulationPersistenceTransition   = Transition<SimulationPersistenceState, SimulationEvent>

public typealias SimulationPersistenceStateMachine = StateMachine<SimulationPersistenceState, SimulationEvent>
extension SimulationPersistenceStateMachine {
    public convenience init() {
        self.init(initialState: .invalid)
        
        // initialiser la StateMachine
        let transition1 =
            SimulationPersistenceTransition(with : .onComputationCompletion,
                                            from : .invalid,
                                            to   : .savable)
        self.add(transition: transition1)
        
        let transition2 =
            SimulationPersistenceTransition(with : .onSaveSuccessfulCompletion,
                                            from : .savable,
                                            to   : .saved)
        self.add(transition: transition2)
        
        let transition3 =
            SimulationPersistenceTransition(with : .onComputationInputsModification,
                                            from : .saved,
                                            to   : .invalid)
        self.add(transition: transition3)
        
        let transition4 =
            SimulationPersistenceTransition(with : .onComputationCompletion,
                                            from : .saved,
                                            to   : .savable)
        self.add(transition: transition4)
        
        let transition5 =
            SimulationPersistenceTransition(with : .onComputationInputsModification,
                                            from : .savable,
                                            to   : .invalid)
        self.add(transition: transition5)
        
        #if DEBUG
        self.enableLogging = true
        #endif
    }
}
