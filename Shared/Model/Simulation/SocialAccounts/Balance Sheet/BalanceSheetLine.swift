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

struct BalanceSheetLine {
    
    // MARK: - Properties
    
    /// Année pour laquelle le Bilan est calculé
    var year: Int = 0
    
    /// Actifs pour la Famille au global et pour chaque membre de la famille
    /// - Note:
    ///   - Pour la Famille, tous les actifs sont incorporés au bilan pour leur valeur globale
    ///   - Pour une personne, les actifs  incorporés sont incorporé (ou pas) et valorisés selon les chois des préférences utilisateur (graphique)
    var assets: [String : ValuedAssets]
    
    /// Passifs pour la Famille au global et pour chaque membre de la famille
    /// - Note:
    ///   - Pour la Famille, tous les passifs sont incorporés au bilan pour leur valeur globale
    ///   - Pour une personne, les passifs  incorporés sont incorporé (ou pas) et valorisés selon les chois des préférences utilisateur (graphique)
    var liabilities: [String : ValuedLiabilities]
    
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
    var netAdultsFinancialAssets : Double {
        (assets[AppSettings.shared.adultsLabel]!.total + liabilities[AppSettings.shared.adultsLabel]!.total)
        - (assets[AppSettings.shared.adultsLabel]!.perCategory[.realEstates]?.total ?? 0)
    }
    
    // MARK: - Initializers
    
    init(year                        : Int,
         withMembersName membersName : [String],
         withAdultsName adultsName   : [String],
         withAssets assets           : [(ownable: OwnableP, category: AssetsCategory)],
         withLiabilities liabilities : [(ownable: OwnableP, category: LiabilitiesCategory)]) {
        //        autoreleasepool {
        self.year = year
        
        // initialiser les dictionnaires
        //  famille
        self.assets      = [AppSettings.shared.allPersonsLabel: ValuedAssets(name: "ACTIF")]
        self.liabilities = [AppSettings.shared.allPersonsLabel: ValuedLiabilities(name : "PASSIF")]
        //  adultes
        self.assets[AppSettings.shared.adultsLabel] = ValuedAssets(name: "ACTIF")
        self.liabilities[AppSettings.shared.adultsLabel] = ValuedLiabilities(name : "PASSIF")
        //  individus
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
            .append((name  : namePrefix + asset.name,
                     value : asset.value(atEndOf: year).rounded()))
        
        //  somme des adultes (filtré et évalué selon préférences graphiques de l'utilisateur)
        var value: Double = 0
        adultsName.forEach { name in
            let selected = isSelected(ownable : asset,
                                      for     : name,
                                      filter  : UserSettings.shared.ownershipGraphicSelection)
            value += valueOf(ownable          : asset,
                             for              : name,
                             isSelected       : selected,
                             evaluationMethod : UserSettings.shared.assetGraphicEvaluationMethod)
        }
        assets[AppSettings.shared.adultsLabel]!.perCategory[category]?.namedValues
            .append((name  : namePrefix + asset.name,
                     value : value))
        
        //  individus  (filtré et évalué selon préférences graphiques de l'utilisateur)
        membersName.forEach { name in
            let selected = isSelected(ownable : asset,
                                      for     : name,
                                      filter  : UserSettings.shared.ownershipGraphicSelection)
            let value = valueOf(ownable          : asset,
                                for              : name,
                                isSelected       : selected,
                                evaluationMethod : UserSettings.shared.assetGraphicEvaluationMethod)
            
            assets[name]!.perCategory[category]?.namedValues
                .append((name  : namePrefix + asset.name,
                         value : value))
        }
    }
    
    fileprivate mutating func appendToLiabilities(_ category    : LiabilitiesCategory,
                                                  _ membersName : [String],
                                                  _ adultsName  : [String],
                                                  _ liability   : OwnableP,
                                                  _ year        : Int) {
        //  famille
        liabilities[AppSettings.shared.allPersonsLabel]!.perCategory[category]?.namedValues
            .append((name  : liability.name,
                     value : liability.value(atEndOf: year).rounded()))
        
        //  adultes
        var value: Double = 0
        adultsName.forEach { name in
            let selected = isSelected(ownable : liability,
                                      for     : name,
                                      filter  : UserSettings.shared.ownershipKpiSelection)
            value += valueOf(ownable          : liability,
                             for              : name,
                             isSelected       : selected,
                             evaluationMethod : UserSettings.shared.assetKpiEvaluationMethod)
        }
        liabilities[AppSettings.shared.adultsLabel]!.perCategory[category]?.namedValues
            .append((name  : liability.name,
                     value : value))

        //  individus
        membersName.forEach { name in
            let selected = isSelected(ownable : liability,
                                      for     : name,
                                      filter  : UserSettings.shared.ownershipGraphicSelection)
            let value = valueOf(ownable          : liability,
                                for              : name,
                                isSelected       : selected,
                                evaluationMethod : UserSettings.shared.assetGraphicEvaluationMethod)
            
            liabilities[name]!.perCategory[category]?.namedValues
                .append( (name  : liability.name,
                          value : value))
        }
    }
    
    /// True si le bien `ownable` satisfait au critère `filter` pour la personne nommée `name`
    /// - Parameters:
    ///   - ownable: un bien
    ///   - name: le nom du de personne dont on calcule le bilan
    ///   - filter: filtre utilisé
    /// - Returns: True si le bien `ownable` satisfait au critère `filter` pour la personne nommée `name`
    fileprivate func isSelected(ownable  : OwnableP,
                                for name : String,
                                filter   : OwnershipNature) -> Bool {
        switch filter {
            
            case .generatesRevenue:
                return ownable.providesRevenue(to: [name])
                
            case .sellable:
                return ownable.hasAFullOwner(in: [name])
                
            case .all:
                return ownable.isPartOfPatrimoine(of: [name])
        }
    }
    
    /// Calcule la valeur du bien `ownable` pour la personne nommée `name` selon la méthode `evaluationMethod`
    /// - Parameters:
    ///   - ownable: un bien
    ///   - isSelected: True si le bien fait partie du type sélectionné dans les préférences utilisateur
    ///   - name: le nom du de personne dont on calcule le bilan
    ///   - evaluationMethod: méthode d'évaluation sélectionnée
    /// - Returns: valeur de `ownable` pour la personne nommée `name` selon la méthode `evaluationMethod`
    fileprivate func valueOf(ownable          : OwnableP,
                             for name         : String,
                             isSelected       : Bool,
                             evaluationMethod : AssetEvaluationMethod) -> Double {
        guard isSelected else {
            return 0
        }
        switch evaluationMethod {
            
            case .totalValue:
                return ownable.value(atEndOf: year).rounded()
                
            case .ownedValue:
                return ownable.ownedValue(by              : name,
                                          atEndOf         : year,
                                          evaluationMethod: .patrimoine).rounded()
        }
    }
}

// MARK: - BalanceSheetLine extensions for VISITORS

extension BalanceSheetLine: BalanceSheetCsvVisitableP {
    func accept(_ visitor: BalanceSheetCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetLineChartVisitableP {
    func accept(_ visitor: BalanceSheetLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension BalanceSheetLine: BalanceSheetCategoryStackedBarChartVisitableP {
    func accept(_ visitor: BalanceSheetCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}
