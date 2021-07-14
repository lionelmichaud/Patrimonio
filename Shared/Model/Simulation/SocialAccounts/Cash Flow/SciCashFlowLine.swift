//
//  SciCashFlowLine.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import FiscalModel
import NamedValue

// ligne anuelle de cash flow de la SCI
struct SciCashFlowLine {
    
    // MARK: - Nested types
    
    /// Agrégat des revenus de la SCI
    struct Revenues {
        
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
    let IS : Double
    
    /// Solde net des Revenus - IS de la SCI
    /// - INCLUS produit de ventes de l'année capitalisé en cours d'années
    var netRevenues : Double { revenues.total - IS }
    
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
    var namesFlatArray: [String] {
        revenues.namesFlatArray + ["SCI-IS"]
    }
    
    /// tableau détaillé des valeurs
    var valuesFlatArray: [Double] {
        revenues.valuesFlatArray + [-IS]
    }
    
    var summary: NamedValueTable {
        var table = NamedValueTable(tableName: "SCI")
        table.namedValues.append((name  : "Revenu SCI",
                                  value : netRevenues))
        return table
    }
    
    // MARK: - Initializers
    
    init(withYear year  : Int,
         of patrimoine  : Patrimoin,
         for adultsName : [String]) {
        self.year = year
        
        // populate produit de vente, dividendes des SCPI
        
        // pour chaque SCPI faisant partie du patrimoine d'une des personnes
        for scpi in patrimoine.assets.sci.scpis.items.sorted(by:<) {
            let scpiName = scpi.name
            // FIXME: Ca ne marche pas comme ca. C'est toute la SCI dont il faut géréer les droit de propriété. Pas chaque SCPI individuellement.
            
            /// Revenus
            var revenue : Double = 0
            if scpi.providesRevenue(to: adultsName) {
                let yearlyRevenue = scpi.yearlyRevenue(during: year)
                let fraction      = scpi.ownership.ownedRevenueFraction(by: adultsName)
                // revenus inscrit en compte courant avant IS
                // dans le cas d'une SCI, le revenu remboursable aux actionnaires c'est le net d'IS
                // FIXME: Les revenus devraient être affectés en fonction des droits de propriété de chacun
                revenue = fraction / 100.0 * yearlyRevenue.revenue
            }
            revenues.scpiDividends.namedValues
                .append((name : scpiName,
                         value: revenue.rounded()))
            
            /// Ventes
            // le produit de la vente se répartit entre UF et NP si démembrement
            // les produits de la vente ne reviennent qu'aux PP ou NP
            // FIXME: Ca ne marche pas comme ca. C'est toute la SCI dont il faut géréer les droit de propriété. Pas chaque SCPI individuellement.
            // populate SCPI sale revenue: produit net de charges sociales et d'impôt sur la plus-value
            // le crédit se fait au début de l'année qui suit la vente
            var netRevenue: Double = 0
            if scpi.isPartOfPatrimoine(of: adultsName) {
                let liquidatedValue = scpi.liquidatedValueIS(year - 1)
                netRevenue = liquidatedValue.netRevenue
                // créditer le produit de la vente sur les comptes des personnes
                // en fonction de leur part de propriété respective
                let ownedSaleValues = scpi.ownedValues(ofValue          : liquidatedValue.netRevenue,
                                                       atEndOf          : year,
                                                       evaluationMethod : .patrimoine)
                let netCashFlowManager = NetCashFlowManager()
                netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                 in            : patrimoine,
                                                 atEndOf       : year)
            }
            revenues.scpiSale.namedValues
                .append((name : scpiName,
                         value: netRevenue.rounded()))
        }
        
        /// calcul de l'IS de la SCI dû sur les dividendes (sur les ventes: déduis au moment de la vente)
        IS = Fiscal.model.companyProfitTaxes.IS(revenues.scpiDividends.total)
    }
    
    // MARK: - Methods
    
    func summaryFiltredNames(with itemSelectionList: ItemSelectionList) -> [String] {
        summary.filtredNames(with : itemSelectionList)
    }
    
    func summaryFiltredValues(with itemSelectionList: ItemSelectionList) -> [Double] {
        summary.filtredValues(with : itemSelectionList)
    }
}

// MARK: - Extensions for VISITORS

extension SciCashFlowLine: CashFlowCsvVisitableP {
    func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension SciCashFlowLine: CashFlowStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension SciCashFlowLine: CashFlowCategoryStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}

extension SciCashFlowLine.Revenues: CashFlowCsvVisitableP {
    func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}
