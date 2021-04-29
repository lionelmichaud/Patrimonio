//
//  Simulation.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 26/04/2021.
//

import Foundation

protocol SimulationReseter {
    func reset(withPatrimoine: Patrimoin)
}

class Simulation: ObservableObject, SimulationReseter {
    func reset(withPatrimoine: Patrimoin) {
        print("simulation.reset")
    }
}
