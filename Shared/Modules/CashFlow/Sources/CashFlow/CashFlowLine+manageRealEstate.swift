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

public extension CashFlowLine {
    /// Populate loyers, produit de la vente et impots locaux des biens immobiliers
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    mutating func manageRealEstateRevenues(of patrimoine            : Patrimoin,
                                           forAdults adultsName     : [String],
                                           forChildren childrenName : [String]) {
        for realEstate in patrimoine.assets.realEstates.items.sorted(by:<) {
            let name = realEstate.name
            
            /// Revenus
            var yearlyAdultsRevenue = (revenue          : 0.0,
                                       taxableIrpp      : 0.0,
                                       socialTaxes      : 0.0,
                                       yearlyLocaltaxes : 0.0)
            var yearlyChildrenRevenue = (revenue          : 0.0,
                                         taxableIrpp      : 0.0,
                                         socialTaxes      : 0.0,
                                         yearlyLocaltaxes : 0.0)
            // les revenus ne reviennent qu'aux UF ou PP, idem pour les impôts locaux
            if realEstate.providesRevenue(to: adultsName) {
                // populate real estate rent revenues and social taxes
                let yearlyRent     = realEstate.yearlyRent(during: year)
                let adultsFraction = realEstate.ownership.ownedRevenueFraction(by: adultsName)
                // loyers inscrit en compte courant avant prélèvements sociaux et IRPP
                // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
                // prélèvements sociaux payés sur le loyer
                // impôts locaux
                yearlyAdultsRevenue = (revenue          : adultsFraction / 100.0 * yearlyRent.revenue,
                                       taxableIrpp      : adultsFraction / 100.0 * yearlyRent.taxableIrpp,
                                       socialTaxes      : adultsFraction / 100.0 * yearlyRent.socialTaxes,
                                       yearlyLocaltaxes : adultsFraction / 100.0 * realEstate.yearlyLocalTaxes(during: year))
            }
            if realEstate.providesRevenue(to: childrenName) {
                // populate real estate rent revenues and social taxes
                let yearlyRent     = realEstate.yearlyRent(during: year)
                let childrenFraction = realEstate.ownership.ownedRevenueFraction(by: childrenName)
                // loyers inscrit en compte courant avant prélèvements sociaux et IRPP
                // part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
                // prélèvements sociaux payés sur le loyer
                // impôts locaux
                yearlyChildrenRevenue = (revenue          : childrenFraction / 100.0 * yearlyRent.revenue,
                                         taxableIrpp      : childrenFraction / 100.0 * yearlyRent.taxableIrpp,
                                         socialTaxes      : childrenFraction / 100.0 * yearlyRent.socialTaxes,
                                         yearlyLocaltaxes : childrenFraction / 100.0 * realEstate.yearlyLocalTaxes(during: year))
            }
            // Adultes
        adultsRevenues: do {
            adultsRevenues
                .perCategory[.realEstateRents]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyAdultsRevenue.revenue.rounded()))
            //   part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
            adultsRevenues
                .perCategory[.realEstateRents]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyAdultsRevenue.taxableIrpp.rounded()))
            //   prélèvements sociaux payés sur le loyer
            adultTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name : name,
                                   value: yearlyAdultsRevenue.socialTaxes.rounded()))
            //   impôts locaux
            adultTaxes
                .perCategory[.localTaxes]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyAdultsRevenue.yearlyLocaltaxes.rounded()))
        }
        childrenRevenues: do {
            // Enfants
            childrenRevenues
                .perCategory[.realEstateRents]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyChildrenRevenue.revenue.rounded()))
            //   part des loyers inscrit en compte courant imposable à l'IRPP - idem ci-dessus car même base
            childrenRevenues
                .perCategory[.realEstateRents]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyChildrenRevenue.taxableIrpp.rounded()))
            //   prélèvements sociaux payés sur le loyer
            childrenTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name : name,
                                   value: yearlyChildrenRevenue.socialTaxes.rounded()))
            //   impôts locaux
            childrenTaxes
                .perCategory[.localTaxes]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: yearlyChildrenRevenue.yearlyLocaltaxes.rounded()))
        }
            /// Vente
            // le produit de la vente se répartit entre UF et NP si démembrement
            var adultsSaleValue   : Double = 0
            var childrenSaleValue : Double = 0
            if realEstate.isPartOfPatrimoine(of: adultsName) || realEstate.isPartOfPatrimoine(of: childrenName) {
                // produit de la vente inscrit en compte courant:
                //    produit net de charges sociales et d'impôt sur la plus-value
                // le crédit se fait au début de l'année qui suit la vente
                let liquidatedValue = realEstate.liquidatedValue(year - 1)
                
                if liquidatedValue.revenue > 0 {
                    // créditer le produit de la vente sur les comptes des personnes
                    // en fonction de leur part de propriété respective
                    let ownedSaleValues = realEstate.ownedValues(ofValue           : liquidatedValue.netRevenue,
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
            // Adultes
            adultsRevenues
                .perCategory[.realEstateSale]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: adultsSaleValue.rounded()))
            // Enfants
            childrenRevenues
                .perCategory[.realEstateSale]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: childrenSaleValue.rounded()))
        }
    }
}
