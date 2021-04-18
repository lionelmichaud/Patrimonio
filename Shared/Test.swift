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
import Retirement
import UnemployementModel
import HumanLifeModel
import FiscalModel

// AppFoundation
let test = SortingOrder.ascending

// Statistics
let point = Point()

// SocioEconomyModel
let tax    = SocioEconomy.RandomVariable.pensionDevaluationRate
let smodel = SocioEconomy.model

// HumanLifeModel
let hlmodel = HumanLife.model

// Retirement
let rmodel = Retirement.model

// UnemployementModel
let uemodel = Unemployment.model
