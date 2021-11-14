//
//  UserSettings.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Foil
import Ownership

public struct UserSettings {
    public static var shared = UserSettings()
    
    // (Key, Value) pairs

    /// Paramètres de simulation
    static let simulateVolatility = "simulateVolatility"
    @WrappedDefault(keyName: UserSettings.simulateVolatility,
                    defaultValue: false)
    public var simulateVolatility: Bool
    
    /// Paramètres de gestion de fichiers
    static let shareCsvFiles = "shareCsvFiles"
    @WrappedDefault(keyName: UserSettings.shareCsvFiles,
                    defaultValue: true)
    public var shareCsvFiles: Bool
    
    static let shareImageFiles = "shareImageFiles"
    @WrappedDefault(keyName: UserSettings.shareImageFiles,
                    defaultValue: true)
    public var shareImageFiles: Bool
    
    /// Paramètres KPI
    static let ownershipKpiSelection = "ownershipKpiSelection"
    @WrappedDefault(keyName: UserSettings.ownershipKpiSelection,
                    defaultValue: OwnershipNature.sellable.rawValue)
    private var ownershipKpiSelectionString: String
    public var ownershipKpiSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipKpiSelectionString) ?? OwnershipNature.sellable
        }
        set {
            ownershipKpiSelectionString = newValue.rawValue
        }
    }
    
    static let assetKpiEvaluatedFraction = "assetKpiEvaluatedFraction"
    @WrappedDefault(keyName: UserSettings.assetKpiEvaluatedFraction,
                    defaultValue: EvaluatedFraction.ownedValue.rawValue)
    private var assetKpiEvaluatedFractionString: String
    public var assetKpiEvaluatedFraction: EvaluatedFraction {
        get {
            EvaluatedFraction(rawValue: assetKpiEvaluatedFractionString) ?? EvaluatedFraction.ownedValue
        }
        set {
            assetKpiEvaluatedFractionString = newValue.rawValue
        }
    }
    
    /// Paramètres Graphiques
    // graphique Bilan
    static let ownershipGraphicSelection = "ownershipGraphicSelection"
    @WrappedDefault(keyName: UserSettings.ownershipGraphicSelection,
                    defaultValue: OwnershipNature.sellable.rawValue)
    private var ownershipGraphicSelectionString: String
    public var ownershipGraphicSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipGraphicSelectionString) ?? OwnershipNature.sellable
        }
        set {
            ownershipGraphicSelectionString = newValue.rawValue
        }
    }
    
    static let assetGraphicEvaluatedFraction = "assetGraphicEvaluatedFraction"
    @WrappedDefault(keyName: UserSettings.assetGraphicEvaluatedFraction,
                    defaultValue: EvaluatedFraction.ownedValue.rawValue)
    private var assetGraphicEvaluatedFractionString: String
    public var assetGraphicEvaluatedFraction: EvaluatedFraction {
        get {
            EvaluatedFraction(rawValue: assetGraphicEvaluatedFractionString) ?? EvaluatedFraction.ownedValue
        }
        set {
            assetGraphicEvaluatedFractionString = newValue.rawValue
        }
    }
    
    // graphique CashFlow
    static let cashFlowGraphicIncludeQuasiUsufruct = "cashFlowGraphicIncludeQuasiUsufruct"
    @WrappedDefault(keyName: UserSettings.cashFlowGraphicIncludeQuasiUsufruct,
                    defaultValue: false)
    public var cashFlowGraphicIncludeQuasiUsufruct: Bool
    
//    static let dictionary = "dictionary"
//    @WrappedDefault(keyName: UserSettings.dictionary,
//                    defaultValue: [EvaluatedFraction.ownedValue : true])
//    public var dictionary: [EvaluatedFraction : Bool]
}
