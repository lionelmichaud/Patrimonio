//
//  SciCashFlowLine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import NamedValue
import ModelEnvironment
import PatrimoineModel

// ligne anuelle de cash flow de la SCI
public struct SciCashFlowLine {
    
    // MARK: - Nested types
    
    /// Agrégat des revenus de la SCI
    public struct Revenues {
        
        // MARK: - Properties
        
        /// Revenus perçus des SCPI de la SCI : avant IS (pas de charge sociales si SCI imposée à l'IS)
        var scpiDividends = NamedValueTable(tableName: "SCI-REVENUS DE SCPI")
        
        /// Ventes des SCPI de la SCI: produit net de charges sociales et d'impôt sur la plus-value
        var scpiSale      = NamedValueTable(tableName: "SCI-VENTES SCPI")
        
        /// Total de tous les revenus nets de l'année: loyers + ventes de la SCI
        var total: Double { scpiDividends.total + scpiSale.total }
        
        /// Total de tous les revenus imposables à l'IS de l'année: loyers + plus-values de la SCI.
        /// Tableau résumé des noms
        var namesArray: [String] {
            ["SCI-" + scpiDividends.tableName, "SCI-" + scpiSale.tableName]
        }
        
        /// Total de tous les revenus imposables à l'IS de l'année: loyers + plus-values de la SCI.
        /// Tableau résumé des valeurs
        var valuesArray: [Double] {
            [scpiDividends.total, scpiSale.total]
        }
        
        /// Total de tous les revenus imposables à l'IS de l'année: loyers + plus-values de la SCI.
        /// Tableau détaillé des noms
        var namesFlatArray: [String] {
            scpiDividends.namesArray.map {$0 + "(Revenu)"} + scpiSale.namesArray.map {$0 + "(Vente)"}
        }
        
        /// Total de tous les revenus imposables à l'IS de l'année: loyers + plus-values de la SCI.
        /// Tableau détaillé des valeurs
        var valuesFlatArray: [Double] {
            scpiDividends.valuesArray + scpiSale.valuesArray
        }
    }
    
    // MARK: - Properties
    
    let year : Int
    
    /// Agrégat des revenus de la SCI - avant IS
    var revenues = Revenues()
    
    // TODO: Ajouter les dépenses de la SCI déductibles du revenu (comptable, gestion, banque...)
    
    /// Impôts sur les société dû par la SCI
    public let IS : Double
    
    /// Solde net des Revenus - IS de la SCI
    /// - INCLUS produit de ventes de l'année capitalisé en cours d'années
    public var netRevenues : Double { revenues.total - IS }
    
    /// Solde net des Revenus - IS de la SCI
    /// - EXCLUS produit de ventes de l'année capitalisé en cours d'années
    var netRevenuesSalesExcluded : Double { revenues.scpiDividends.total - IS }
    
    /// tableau résumé des noms
    var namesArray: [String] {
        revenues.namesArray + ["SCI-IS"]
    }
    
    /// tableau résumé des valeurs
    var valuesArray: [Double] {
        Swift.print(revenues.valuesArray + [-IS])
        return revenues.valuesArray + [-IS]
    }
    
    /// tableau détaillé des noms
    public var namesFlatArray: [String] {
        revenues.namesFlatArray + ["SCI-IS"]
    }
    
    /// tableau détaillé des valeurs
    public var valuesFlatArray: [Double] {
        revenues.valuesFlatArray + [-IS]
    }
    
    public var summary: NamedValueTable {
        var table = NamedValueTable(tableName: "SCI")
        table.namedValues.append(NamedValue(name  : "Revenu SCI",
                                            value : netRevenues))
        return table
    }
    
    // MARK: - Initializers
    
    init() {
        year = CalendarCst.thisYear
        IS = 0.0
    }
    
    init(withYear year  : Int,
         of patrimoine  : Patrimoin,
         for adultsName : [String],
         using model    : Model) {
        self.year = year
        
        // populate produit de vente, dividendes des SCPI
        
        // pour chaque SCPI faisant partie du patrimoine d'une des personnes
        for scpi in patrimoine.assets.sci.scpis.items.sorted(by:<) {
            let scpiName = scpi.name
            // FIXME: Ca ne marche pas comme ca. C'est toute la SCI dont il faut géréer les droit de propriété. Pas chaque SCPI individuellement.
            
            /// Revenus
            var adultDividendsRevenue : Double = 0
            if scpi.providesRevenue(to: adultsName) {
                let yearlyRevenue = scpi.yearlyRevenueIS(during: year)
                let adultFraction = scpi.ownership.ownedRevenueFraction(by: adultsName)
                // revenus inscrit en compte courant avant IS
                // dans le cas d'une SCI, le revenu remboursable aux actionnaires c'est le net d'IS
                // FIXME: Les revenus devraient être affectés en fonction des droits de propriété de chacun, y.c. aux enfants
                adultDividendsRevenue = adultFraction / 100.0 * yearlyRevenue
            }
            // FIXME: Les revenus devraient être affectés en fonction des droits de propriété de chacun, y.c. aux enfants
            revenues.scpiDividends.namedValues
                .append(NamedValue(name : scpiName,
                                   value: adultDividendsRevenue.rounded()))
            
            /// Ventes
            // le produit de la vente se répartit entre UF et NP si démembrement
            // les produits de la vente ne reviennent qu'aux PP ou NP
            // FIXME: Ca ne marche pas comme ca. C'est toute la SCI dont il faut géréer les droit de propriété. Pas chaque SCPI individuellement.
            // populate SCPI sale revenue: produit net d'impôt (IS) sur la plus-value
            // le crédit se fait au début de l'année qui suit la vente
            var adultSaleNetRevenue: Double = 0
            if scpi.isPartOfPatrimoine(of: adultsName) {
                let liquidatedValue = scpi.liquidatedValueIS(year - 1)
                if liquidatedValue.revenue > 0 {
                    let saleNetRevenue = liquidatedValue.netRevenue
                    // créditer le produit de la vente sur les comptes des personnes
                    // en fonction de leur part de propriété respective
                    let ownedSaleValues = scpi.ownedValues(ofValue           : saleNetRevenue,
                                                           atEndOf           : year,
                                                           evaluationContext : .patrimoine)
                    let netCashFlowManager = NetCashFlowManager()
                    netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                     in            : patrimoine,
                                                     atEndOf       : year)
                    // FIXME: Les revenus devraient être affectés en fonction des droits de propriété de chacun, y.c. aux enfants
                    let adultFraction = scpi.ownership.ownedRevenueFraction(by: adultsName)
                    adultSaleNetRevenue = adultFraction / 100.0 * saleNetRevenue
                }
            }
            // FIXME: Les revenus devraient être affectés en fonction des droits de propriété de chacun, y.c. aux enfants
            revenues.scpiSale.namedValues
                .append(NamedValue(name : scpiName,
                                   value: adultSaleNetRevenue.rounded()))
        }
        
        /// calcul de l'IS de la SCI dû sur le total des dividendes (sur les ventes: déduit au moment de la vente)
        // dans le cas d'une SCI, le revenu remboursable aux actionnaires c'est le net d'IS
        IS = model.fiscalModel.companyProfitTaxes.IS(revenues.scpiDividends.total)
    }
    
    // MARK: - Methods
    
    public func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with : itemSelectionList)
    }
    
    public func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with : itemSelectionList)
    }
}

// MARK: - Extensions for VISITORS

extension SciCashFlowLine: CashFlowCsvVisitableP {
    public func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension SciCashFlowLine: CashFlowStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension SciCashFlowLine: CashFlowCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}

extension SciCashFlowLine.Revenues: CashFlowCsvVisitableP {
    public func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}
