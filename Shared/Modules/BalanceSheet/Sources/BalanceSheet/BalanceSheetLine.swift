//
//  BalanceSheetLine.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/05/2021.
//

import Foundation
import NamedValue
import Persistence
import Ownership
import AssetsModel
import Liabilities

// MARK: - Ligne de Bilan annuel

public struct BalanceSheetLine {
    
    // MARK: - Properties
    
    /// Année pour laquelle le Bilan est calculé
    public var year: Int = 0
    
    /// Actifs pour la Famille au global et pour chaque membre de la famille
    /// - Note:
    ///   - Pour la Famille, tous les actifs sont incorporés au bilan pour leur valeur globale
    ///   - Pour une personne, les actifs  incorporés sont incorporé (ou pas) et valorisés selon les chois des préférences utilisateur (graphique)
    public var assets: [String : ValuedAssets]
    
    /// Passifs pour la Famille au global et pour chaque membre de la famille
    /// - Note:
    ///   - Pour la Famille, tous les passifs sont incorporés au bilan pour leur valeur globale
    ///   - Pour une personne, les passifs  incorporés sont incorporé (ou pas) et valorisés selon les chois des préférences utilisateur (graphique)
    public var liabilities: [String : ValuedLiabilities]
    
    /// Actifs Nets de la Famille entière
    /// - Note:
    ///   - Tous les biens sont incorporés au bilan pour leur valeur globale
    var netFamilyAssets: Double {
        assets[AppSettings.shared.allPersonsLabel]!.total
            + liabilities[AppSettings.shared.allPersonsLabel]!.total
    }
    
    /// Actifs Nets de la Famille entière EXCLUANT l'immobilier physique
    /// - Note:
    ///   - Les biens sont incorporés au bilan pour leur valeur globale
    var netFamilyFinancialAssets : Double {
        netFamilyAssets
            - (assets[AppSettings.shared.allPersonsLabel]!.perCategory[.realEstates]?.total ?? 0)
    }
    
    /// Actifs Nets des Adults EXCLUANT l'immobilier physique
    /// - Note:
    ///   - Les biens sont incorporés au bilan pour leur valeur selon la méthode de calcul des préférences utilisateur
    public var netAdultsFinancialAssets : Double {
        (assets[AppSettings.shared.adultsLabel]!.total + liabilities[AppSettings.shared.adultsLabel]!.total)
            - (assets[AppSettings.shared.adultsLabel]!.perCategory[.realEstates]?.total ?? 0)
    }
    
    // MARK: - Initializers
    
    public init(year                        : Int,
                withMembersName membersName : [String],
                withAdultsName adultsName   : [String],
                withAssets assets           : [(ownable: OwnableP, category: AssetsCategory)],
                withLiabilities liabilities : [(ownable: OwnableP, category: LiabilitiesCategory)]) {
        //        autoreleasepool {
        self.year = year
        
        // initialiser les dictionnaires
        //  - toute la famille
        self.assets      = [AppSettings.shared.allPersonsLabel: ValuedAssets(name: "ACTIF")]
        self.liabilities = [AppSettings.shared.allPersonsLabel: ValuedLiabilities(name : "PASSIF")]
        //  - ensemble des adultes
        self.assets[AppSettings.shared.adultsLabel] = ValuedAssets(name: "ACTIF")
        self.liabilities[AppSettings.shared.adultsLabel] = ValuedLiabilities(name : "PASSIF")
        //  - individuels
        membersName.forEach { name in
            self.assets[name]      = ValuedAssets(name : "ACTIF")
            self.liabilities[name] = ValuedLiabilities(name : "PASSIF")
        }
        
        // actifs
        for asset in assets {
            appendToAssets(asset.category,
                           membersName,
                           adultsName,
                           asset.ownable,
                           year)
        }
        
        // dettes
        for liability in liabilities {
            appendToLiabilities(liability.category,
                                membersName,
                                adultsName,
                                liability.ownable,
                                year)
        }
        //        }
    }
    
    // MARK: - Methods
    
    fileprivate mutating func appendToAssets(_ category    : AssetsCategory,
                                             _ membersName : [String],
                                             _ adultsName  : [String],
                                             _ asset       : OwnableP,
                                             _ year        : Int) {
        let namePrefix: String = (category == .sci ? "SCI - " : "")
        
        //  famille
        assets[AppSettings.shared.allPersonsLabel]!
            .perCategory[category]?
            .namedValues
            .append(NamedValue(name  : namePrefix + asset.name,
                               value : asset.value(atEndOf: year).rounded()))
        
        //  somme des adultes (filtré et évalué selon préférences graphiques de l'utilisateur)
        var value: Double = 0
        adultsName.forEach { name in
            value += asset.ownedValue(by                  : name,
                                      atEndOf             : year,
                                      withOwnershipNature : Preferences.standard.ownershipGraphicSelection,
                                      evaluatedFraction   : Preferences.standard.assetGraphicEvaluatedFraction)
        }
        assets[AppSettings.shared.adultsLabel]!
            .perCategory[category]?
            .namedValues
            .append(NamedValue(name  : namePrefix + asset.name,
                               value : value))
        
        //  individus (filtré et évalué selon préférences graphiques de l'utilisateur)
        membersName.forEach { name in
            let value = asset.ownedValue(by                  : name,
                                         atEndOf             : year,
                                         withOwnershipNature : Preferences.standard.ownershipGraphicSelection,
                                         evaluatedFraction   : Preferences.standard.assetGraphicEvaluatedFraction)
            
            assets[name]!
                .perCategory[category]?
                .namedValues
                .append(NamedValue(name  : namePrefix + asset.name,
                                   value : value))
        }
    }
    
    fileprivate mutating func appendToLiabilities(_ category    : LiabilitiesCategory,
                                                  _ membersName : [String],
                                                  _ adultsName  : [String],
                                                  _ liability   : OwnableP,
                                                  _ year        : Int) {
        //  famille
        liabilities[AppSettings.shared.allPersonsLabel]!
            .perCategory[category]?
            .namedValues
            .append(NamedValue(name  : liability.name,
                               value : liability.value(atEndOf: year).rounded()))
        
        //  somme des adultes (filtré et évalué selon préférences graphiques de l'utilisateur)
        var value: Double = 0
        adultsName.forEach { name in
            value += liability.ownedValue(by                  : name,
                                          atEndOf             : year,
                                          withOwnershipNature : Preferences.standard.ownershipGraphicSelection,
                                          evaluatedFraction   : Preferences.standard.assetGraphicEvaluatedFraction)
        }
        liabilities[AppSettings.shared.adultsLabel]!
            .perCategory[category]?
            .namedValues
            .append(NamedValue(name  : liability.name,
                               value : value))
        
        //  individus (filtré et évalué selon préférences graphiques de l'utilisateur)
        membersName.forEach { name in
            let value = liability.ownedValue(by                  : name,
                                             atEndOf             : year,
                                             withOwnershipNature : Preferences.standard.ownershipGraphicSelection,
                                             evaluatedFraction   : Preferences.standard.assetGraphicEvaluatedFraction)
            liabilities[name]!
                .perCategory[category]?
                .namedValues
                .append(NamedValue(name  : liability.name,
                                   value : value))
        }
    }
}

// MARK: - BalanceSheetLine extensions for VISITORS

extension BalanceSheetLine: BalanceSheetCsvVisitableP {
    public func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetLineChartVisitableP {
    public func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
