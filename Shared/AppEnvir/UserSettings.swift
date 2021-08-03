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

// MARK: - Enumération de nature d'une propriété

enum OwnershipNature: String, PickableEnumP {
    case generatesRevenue = "Uniquement les biens génèrant revenu/dépense (possédés en PP ou en UF au moins en partie)"
    case sellable         = "Uniquement les biens cessibles (possédés en PP au moins en partie)"
    case all              = "Tous les biens (possédés en UF, NP ou PP au moins en partie)"
    
    var pickerString: String {
        return self.rawValue
    }
}

enum AssetEvaluationMethod: String, PickableEnumP {
    case totalValue = "Valeur totale du bien"
    case ownedValue = "Valeur patrimoniale de la fraction possédée du bien"
    
    var pickerString: String {
        return self.rawValue
    }
}

struct UserSettings {
    static var shared = UserSettings()
    
    // (Key, Value) pairs

    // paramètres de simulation
    static let simulateVolatility = "simulateVolatility"
    @WrappedDefault(keyName: UserSettings.simulateVolatility,
                    defaultValue: false)
    var simulateVolatility: Bool
    
    // paramètres de gestion de fichiers
    static let shareCsvFiles = "shareCsvFiles"
    @WrappedDefault(keyName: UserSettings.shareCsvFiles,
                    defaultValue: true)
    var shareCsvFiles: Bool
    
    static let shareImageFiles = "shareImageFiles"
    @WrappedDefault(keyName: UserSettings.shareImageFiles,
                    defaultValue: true)
    var shareImageFiles: Bool
    
    // paramètres KPI
    static let ownershipKpiSelection = "ownershipKpiSelection"
    @WrappedDefault(keyName: UserSettings.ownershipKpiSelection,
                    defaultValue: OwnershipNature.sellable.rawValue)
    var ownershipKpiSelectionString: String
    var ownershipKpiSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipKpiSelectionString) ?? OwnershipNature.sellable
        }
        set {
            ownershipKpiSelectionString = newValue.rawValue
        }
    }
    
    static let assetKpiEvaluationMethod = "assetKpiEvaluationMethod"
    @WrappedDefault(keyName: UserSettings.assetKpiEvaluationMethod,
                    defaultValue: AssetEvaluationMethod.ownedValue.rawValue)
    var assetKpiEvaluationMethodString: String
    var assetKpiEvaluationMethod: AssetEvaluationMethod {
        get {
            AssetEvaluationMethod(rawValue: assetKpiEvaluationMethodString) ?? AssetEvaluationMethod.ownedValue
        }
        set {
            assetKpiEvaluationMethodString = newValue.rawValue
        }
    }
    
    // paramètres Graphiques
    static let ownershipGraphicSelection = "ownershipGraphicSelection"
    @WrappedDefault(keyName: UserSettings.ownershipGraphicSelection,
                    defaultValue: OwnershipNature.sellable.rawValue)
    var ownershipGraphicSelectionString: String
    var ownershipGraphicSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipGraphicSelectionString) ?? OwnershipNature.sellable
        }
        set {
            ownershipGraphicSelectionString = newValue.rawValue
        }
    }
    
    static let assetGraphicEvaluationMethod = "assetGraphicEvaluationMethod"
    @WrappedDefault(keyName: UserSettings.assetGraphicEvaluationMethod,
                    defaultValue: AssetEvaluationMethod.ownedValue.rawValue)
    var assetGraphicEvaluationMethodString: String
    var assetGraphicEvaluationMethod: AssetEvaluationMethod {
        get {
            AssetEvaluationMethod(rawValue: assetGraphicEvaluationMethodString) ?? AssetEvaluationMethod.ownedValue
        }
        set {
            assetGraphicEvaluationMethodString = newValue.rawValue
        }
    }
}
