//
//  UIState.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 17/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import NamedValue
import Persistence
import LifeExpense
import BalanceSheet
import CashFlow

final class UIState: ObservableObject {
    enum Tab: Int, Hashable {
        case userSettings, dossier, family, expense, asset, scenario, simulation
    }
    
    // MARK: - Etat de la vue Patrimoine
    struct AssetsViewState {
        var expandAsset      : Bool = true
        var expandImmobilier : Bool = true
        var expandFinancier  : Bool = true
        var expandSCI        : Bool = true
        var expandEstate     : Bool = false
        var expandSCPI       : Bool = false
        var expandPeriodic   : Bool = false
        var expandFree       : Bool = false
        var expandSCISCPI    : Bool = false
    }
    struct LiabilitiesViewState {
        var expandLiab        : Bool = true
        var expandEmprunts    : Bool = false
        var expandDettes      : Bool = false
    }
    struct PatrimoineViewState {
        var evalDate       : Double = CalendarCst.thisYear.double()
        var assetViewState = AssetsViewState()
        var liabViewState  = LiabilitiesViewState()
    }
    
    // MARK: - Etat de la vue Expense
    struct ExpenseViewState {
        var expandCategories  : [Bool] = []
        var endDate           : Double = (CalendarCst.thisYear + 25).double()
        var evalDate          : Double = CalendarCst.thisYear.double()
        var selectedCategory  : LifeExpenseCategory = .abonnements
    }
    
    // MARK: - Etat de la vue Modèles
    struct ModelViewState {
        var selectedItem: ModelsSidebarView.PushedItem? = .modelManager
    }
    
    // MARK: - Etat de la vue Simulation
    struct SimulationViewState {
        var selectedItem: SimulationSidebarView.PushedItem? = .computationView
    }
    
    // MARK: - Etat de la vue Compute
    struct ComputationState {
        var nbYears : Double = 50
        var nbRuns  : Double = 100
    }
    
    // MARK: - Etat des filtres graphes Bilan
    struct BalanceSheetChartState {
        var nameSelection : String             = AppSettings.shared.allPersonsLabel
        var combination   : BalanceCombination = .both
        var itemSelection : ItemSelectionList  = []
    }
    
    // MARK: - Etat des filtres graphes Cash Flow
    struct CashFlowChartState {
        var parentChildrenSelection : String            = AppSettings.shared.adultsLabel
        var combination             : CashCombination   = .both
        var itemSelection           : ItemSelectionList = []
        var onlyOneCategorySeleted  : Bool {
            let count = itemSelection.reduce(.zero, { result, element in result + (element.selected ? 1 : 0) })
            return count == 1
        }
        var selectedExpenseCategory: LifeExpenseCategory = .abonnements
    }
    
    // MARK: - Etat de la vue Expense
    struct FiscalChartState {
        var evalDate: Double = CalendarCst.thisYear.double()
    }

//    @Published var selectedTab         : Tab  = Tab.dossier
//    @Published var selectedSideBarItem : Tab? = Tab.family
    @Published var patrimoineViewState = PatrimoineViewState()
    @Published var modelsViewState     = ModelViewState()
    @Published var simulationViewState = SimulationViewState()
    @Published var expenseViewState    = ExpenseViewState()
    @Published var computationState    = ComputationState()
    @Published var bsChartState        = BalanceSheetChartState()
    @Published var cfChartState        = CashFlowChartState()
    @Published var fiscalChartState    = FiscalChartState()

    // MARK: - Initializers
    
    init() {
        expenseViewState.expandCategories = Array(repeating: false, count: LifeExpenseCategory.allCases.count)
    }
    
    // MARK: - Subscripts
    
    subscript(category: LifeExpenseCategory) -> Bool {
        get {
            self.expenseViewState.expandCategories[category.rawValue]
        }
        set {
            self.expenseViewState.expandCategories[category.rawValue] = newValue
        }
    }

    // MARK: - methods
    
    func resetSimulationView() {
        simulationViewState.selectedItem = .computationView
    }
}
