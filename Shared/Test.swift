//
//  Test.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 18/04/2021.
//

import Foundation
import AppFoundation
import Statistics
import SocioEconomyModel
import UnemployementModel
import Retirement

// AppFoundation
let test = SortingOrder.ascending

// Statistics
let point = Point()

// SocioEconomyModel
let tax    = SocioEconomy.RandomVariable.pensionDevaluationRate
let smodel = SocioEconomy.model

// UnemployementModel
let uemodel = Unemployment.model

// Retirement
let rmodel = Retirement.model
