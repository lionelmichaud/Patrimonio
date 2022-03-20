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

public extension CashFlowLine {
    /// Populate produit de vente, dividendes, taxes sociales des SCPI hors de la SCI
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: les adultes vivants de la famille
    ///   - childrenName: les enfants vivants de la famille
    mutating func manageScpiRevenues(of patrimoine            : Patrimoin,
                                     forAdults adultsName     : [String],
                                     forChildren childrenName : [String]) {
        for scpi in patrimoine.assets.scpis.items.sorted(by:<) {
            let scpiName = scpi.name
            
            /// Revenus
            var yearlyAdultsRevenue = (revenue     : 0.0,
                                       taxableIrpp : 0.0,
                                       socialTaxes : 0.0)
            var yearlyChildrenRevenue = (revenue     : 0.0,
                                         taxableIrpp : 0.0,
                                         socialTaxes : 0.0)
            if scpi.providesRevenue(to: adultsName) {
                // populate SCPI revenues and social taxes
                let yearlyRevenue  = scpi.yearlyRevenueIRPP(during: year)
                let adultsFraction = scpi.ownership.ownedRevenueFraction(by: adultsName)
                // dividendes inscrit en compte courant avant prélèvements sociaux et IRPP
                // part des dividendes inscrit en compte courant imposable à l'IRPP
                // prélèvements sociaux payés sur les dividendes de SCPI
                yearlyAdultsRevenue = (revenue    : adultsFraction / 100.0 * yearlyRevenue.revenue,
                                       taxableIrpp: adultsFraction / 100.0 * yearlyRevenue.taxableIrpp,
                                       socialTaxes: adultsFraction / 100.0 * yearlyRevenue.socialTaxes)
            }
            if scpi.providesRevenue(to: childrenName) {
                // populate SCPI revenues and social taxes
                let yearlyRevenue    = scpi.yearlyRevenueIRPP(during: year)
                let childrenFraction = scpi.ownership.ownedRevenueFraction(by: childrenName)
                // dividendes inscrit en compte courant avant prélèvements sociaux et IRPP
                // part des dividendes inscrit en compte courant imposable à l'IRPP
                // prélèvements sociaux payés sur les dividendes de SCPI
                yearlyChildrenRevenue = (revenue    : childrenFraction / 100.0 * yearlyRevenue.revenue,
                                         taxableIrpp: childrenFraction / 100.0 * yearlyRevenue.taxableIrpp,
                                         socialTaxes: childrenFraction / 100.0 * yearlyRevenue.socialTaxes)
            }
            // Adultes
        adultsRevenues: do {
            adultsRevenues
                .perCategory[.scpis]?
                .credits
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: yearlyAdultsRevenue.revenue.rounded()))
            adultsRevenues
                .perCategory[.scpis]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: yearlyAdultsRevenue.taxableIrpp.rounded()))
            adultTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: yearlyAdultsRevenue.socialTaxes.rounded()))
        }
        childrenRevenues: do {
            // Enfants
            childrenRevenues
                .perCategory[.scpis]?
                .credits
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: yearlyChildrenRevenue.revenue.rounded()))
            childrenRevenues
                .perCategory[.scpis]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: yearlyChildrenRevenue.taxableIrpp.rounded()))
            childrenTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: yearlyChildrenRevenue.socialTaxes.rounded()))
        }
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            // populate SCPI sale revenue: produit de vente net de charges sociales et d'impôt sur la plus-value
            // le crédit se fait au début de l'année qui suit la vente
            var adultsSaleValue   : Double = 0
            var childrenSaleValue : Double = 0
            if scpi.isPartOfPatrimoine(of: adultsName) || scpi.isPartOfPatrimoine(of: childrenName) {
                let liquidatedValue = scpi.liquidatedValueIRPP(year - 1)
                
                if liquidatedValue.revenue > 0 {
                    // créditer le produit de la vente sur les comptes des personnes
                    // en fonction de leur part de propriété respective
                    let ownedSaleValues = scpi.ownedValues(ofValue           : liquidatedValue.netRevenue,
                                                           atEndOf           : year,
                                                           evaluationContext : .patrimoine)
                    let netCashFlowManager = NetCashFlowManager()
                    netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                     in            : patrimoine,
                                                     atEndOf       : year)
                    // produit net de la vente revenant aux adults
                    adultsSaleValue = ownedSaleValues.map { key, value in
                        adultsName.contains(key) ? value : 0.0
                    }.sum()
                    // produit net de la vente revenant aux enfants
                    childrenSaleValue = ownedSaleValues.map { key, value in
                        childrenName.contains(key) ? value : 0.0
                    }.sum()
                }
                
            }
            // pour garder le nombre de séries graphiques constant au cours du temps
            adultsRevenues
                .perCategory[.scpiSale]?
                .credits
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: adultsSaleValue.rounded()))
            childrenRevenues
                .perCategory[.scpiSale]?
                .credits
                .namedValues
                .append(NamedValue(name: scpiName,
                                   value: childrenSaleValue.rounded()))
        }
    }
}
