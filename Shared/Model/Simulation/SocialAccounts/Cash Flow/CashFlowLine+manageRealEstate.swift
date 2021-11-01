//
//  CashFlowLine+manageRealEstate.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import PatrimoineModel
import NamedValue

extension CashFlowLine {
    /// Populate loyers, produit de la vente et impots locaux des biens immobiliers
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    mutating func manageRealEstateRevenues(of patrimoine  : Patrimoin,
                                           for adultsName : [String]) {
        for realEstate in patrimoine.assets.realEstates.items.sorted(by:<) {
            let name = realEstate.name
            
            /// Revenus
            var revenue          : Double = 0
            var taxableIrpp      : Double = 0
            var socialTaxes      : Double = 0
            var yearlyLocaltaxes : Double = 0
            // les revenus ne reviennent qu'aux UF ou PP, idem pour les impôts locaux
            if realEstate.providesRevenue(to: adultsName) {
                // populate real estate rent revenues and social taxes
                let yearlyRent = realEstate.yearlyRent(during: year)
                let fraction   = realEstate.ownership.ownedRevenueFraction(by: adultsName)
                // loyers inscrit en compte courant avant prélèvements sociaux et IRPP
                revenue          = fraction / 100.0 * yearlyRent.revenue
                // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
                taxableIrpp      = fraction / 100.0 * yearlyRent.taxableIrpp
                // prélèvements sociaux payés sur le loyer
                socialTaxes      = fraction / 100.0 * yearlyRent.socialTaxes
                // impôts locaux
                yearlyLocaltaxes = fraction / 100.0 * realEstate.yearlyLocalTaxes(during: year)
            }
            adultsRevenues
                .perCategory[.realEstateRents]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: revenue.rounded()))
            // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
            adultsRevenues
                .perCategory[.realEstateRents]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: name,
                                   value: taxableIrpp.rounded()))
            // prélèvements sociaux payés sur le loyer
            adultTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name : name,
                                   value: socialTaxes.rounded()))
            // impôts locaux
            adultTaxes
                .perCategory[.localTaxes]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyLocaltaxes.rounded()))
            
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            var netRevenue: Double = 0
            if realEstate.isPartOfPatrimoine(of: adultsName) {
                // produit de la vente inscrit en compte courant:
                //    produit net de charges sociales et d'impôt sur la plus-value
                // le crédit se fait au début de l'année qui suit la vente
                let liquidatedValue = realEstate.liquidatedValue(year - 1)
                netRevenue = liquidatedValue.netRevenue
                // créditer le produit de la vente sur les comptes des personnes
                // en fonction de leur part de propriété respective
                let ownedSaleValues = realEstate.ownedValues(ofValue           : liquidatedValue.netRevenue,
                                                             atEndOf           : year,
                                                             evaluationContext : .patrimoine)
                let netCashFlowManager = NetCashFlowManager()
                netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                 in            : patrimoine,
                                                 atEndOf       : year)
            }
            adultsRevenues
                .perCategory[.realEstateSale]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: netRevenue.rounded()))
        }
    }
}
