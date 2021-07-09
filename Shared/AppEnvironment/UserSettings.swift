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

enum OwnershipNature: String, PickableEnum {
    case generatesRevenue = "Uniquement les biens génèrant revenu/dépense (possédés en PP ou en UF au moins en partie)"
    case sellable         = "Uniquement les biens cessibles (possédés en PP au moins en partie)"
    case all              = "Tous les biens (possédés en UF, NP ou PP au moins en partie)"
    
    var pickerString: String {
        return self.rawValue
    }
}

enum AssetEvaluationMethod: String, PickableEnum {
    case totalValue = "Valeur totale du bien"
    case ownedValue = "Valeur de la fraction possédée du bien"
    
    var pickerString: String {
        return self.rawValue
    }
}

struct UserSettings {
    static var shared = UserSettings()
    
    // (Key, Value) pairs

    static let simulateVolatility    = "simulateVolatility"
    @WrappedDefault(keyName: UserSettings.simulateVolatility,
                    defaultValue: false)
    var simulateVolatility: Bool
    
    static let shareCsvFiles         = "shareCsvFiles"
    @WrappedDefault(keyName: UserSettings.shareCsvFiles,
                    defaultValue: true)
    var shareCsvFiles: Bool
    
    static let shareImageFiles       = "shareImageFiles"
    @WrappedDefault(keyName: UserSettings.shareImageFiles,
                    defaultValue: true)
    var shareImageFiles: Bool
    
    static let ownershipSelection    = "ownershipSelection"
    @WrappedDefault(keyName: UserSettings.ownershipSelection,
                    defaultValue: OwnershipNature.all.rawValue)
    var ownershipSelectionString: String
    var ownershipSelection: OwnershipNature {
        get {
            OwnershipNature(rawValue: ownershipSelectionString) ?? OwnershipNature.all
        }
        set {
            ownershipSelectionString = newValue.rawValue
        }
    }
    
    static let assetEvaluationMethod = "assetEvaluationMethod"
    @WrappedDefault(keyName: UserSettings.assetEvaluationMethod,
                    defaultValue: AssetEvaluationMethod.ownedValue.rawValue)
    var assetEvaluationMethodString: String
    var assetEvaluationMethod: AssetEvaluationMethod {
        get {
            AssetEvaluationMethod(rawValue: assetEvaluationMethodString) ?? AssetEvaluationMethod.ownedValue
        }
        set {
            assetEvaluationMethodString = newValue.rawValue
        }
    }

}
