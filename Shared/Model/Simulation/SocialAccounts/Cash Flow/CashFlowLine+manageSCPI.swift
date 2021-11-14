//
//  CashFlowLine+manageSCPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import PatrimoineModel
import NamedValue

extension CashFlowLine {
    /// Populate produit de vente, dividendes, taxes sociales des SCPI hors de la SCI
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    mutating func manageScpiRevenues(of patrimoine  : Patrimoin,
                                     for adultsName : [String]) {
        for scpi in patrimoine.assets.scpis.items.sorted(by:<) {
            let scpiName = scpi.name
            
            /// Revenus
            var revenue     : Double = 0
            var taxableIrpp : Double = 0
            var socialTaxes : Double = 0
            if scpi.providesRevenue(to: adultsName) {
                // populate SCPI revenues and social taxes
                let yearlyRevenue = scpi.yearlyRevenue(during: year)
                let fraction      = scpi.ownership.ownedRevenueFraction(by: adultsName)
                // dividendes inscrit en compte courant avant prélèvements sociaux et IRPP
                revenue     = fraction / 100.0 * yearlyRevenue.revenue
                // part des dividendes inscrit en compte courant imposable à l'IRPP
                taxableIrpp = fraction / 100.0 * yearlyRevenue.taxableIrpp
                // prélèvements sociaux payés sur les dividendes de SCPI
                socialTaxes = fraction / 100.0 * yearlyRevenue.socialTaxes
            }
            adultsRevenues
                .perCategory[.scpis]?
                .credits
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: revenue.rounded()))
            adultsRevenues
                .perCategory[.scpis]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: taxableIrpp.rounded()))
            adultTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: socialTaxes.rounded()))
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            // populate SCPI sale revenue: produit de vente net de charges sociales et d'impôt sur la plus-value
            // le crédit se fait au début de l'année qui suit la vente
            var netRevenue: Double = 0
            if scpi.isPartOfPatrimoine(of: adultsName) {
                let liquidatedValue = scpi.liquidatedValueIRPP(year - 1)
                
                if liquidatedValue.revenue > 0 {
                    netRevenue = liquidatedValue.netRevenue
                    // créditer le produit de la vente sur les comptes des personnes
                    // en fonction de leur part de propriété respective
                    let ownedSaleValues = scpi.ownedValues(ofValue           : liquidatedValue.netRevenue,
                                                           atEndOf           : year,
                                                           evaluationContext : .patrimoine)
                    let netCashFlowManager = NetCashFlowManager()
                    netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                     in            : patrimoine,
                                                     atEndOf       : year)
                }
                
            }
            // pour garder le nombre de séries graphiques constant au cours du temps
            adultsRevenues
                .perCategory[.scpiSale]?
                .credits
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: netRevenue.rounded()))
        }
    }
}
