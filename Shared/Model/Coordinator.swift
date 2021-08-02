//
//  Coordinator.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 02/05/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel
import RetirementModel
import UnemployementModel
import EconomyModel
import SocioEconomyModel

/// - Warning: Attention on fait des copies des Singletons ce qui suppose que ceux-ci
///   sont 'stateless' car les originaux et les copies ne seront PAS synchronisées.
///   A moins que les Singleton soient des Class.
struct Coordinator {
    static let shared = Coordinator()
    
    /// Coordonne les diffférents singletons du modèle en terme de dépendance
    /// - Warning: Doit être appelé avant l'utilisation du Modèle
    init() {
    }
}
