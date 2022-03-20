//
//  CashFlowLine+managePeriodicInvest.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import PatrimoineModel
import NamedValue

public extension CashFlowLine {
    /// Gère le produit de la vente des investissements financiers périodiques + les versements périodiques à réaliser
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    mutating func managePeriodicInvestmentRevenues(of patrimoine            : Patrimoin,
                                                   forAdults adultsName     : [String],
                                                   forChildren childrenName : [String],
                                                   lifeInsuranceRebate      : inout Double) {
        // pour chaque investissement financier periodique
        for periodicInvestement in patrimoine.assets.periodicInvests.items.sorted(by:<) {
            let name = periodicInvestement.name
            var adultsSaleValue   : Double = 0
            var childrenSaleValue : Double = 0
            var taxablesIrpp      : Double = 0
            var socialTaxes       : Double = 0
            var yearlyPayement    : Double = 0
            var adultFraction     : Double = 1.0

            if periodicInvestement.isPartOfPatrimoine(of: adultsName) {
                /// Ventes de l'année
                // le crédit se fait au début de l'année qui suit la vente
                let liquidatedValue = periodicInvestement.liquidatedValue(atEndOf: year - 1)
                
                if liquidatedValue.revenue > 0 {
                    // produit de la liquidation inscrit en compte courant avant prélèvements sociaux et IRPP
                    // créditer le produit de la vente sur les comptes des personnes
                    // en fonction de leur part de propriété respective
                    let ownedSaleValues = periodicInvestement.ownedValues(ofValue           : liquidatedValue.revenue,
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
                    adultFraction = adultsSaleValue / liquidatedValue.revenue
                    // produit net de la vente revenant aux enfants
                    childrenSaleValue = ownedSaleValues.map { key, value in
                        childrenName.contains(key) ? value : 0.0
                    }.sum()

                    // populate plus values taxables à l'IRPP
                    switch periodicInvestement.type {
                        case .lifeInsurance:
                            @ZeroOrPositive var taxableInterests: Double
                            // apply rebate if some is remaining
                            taxableInterests = liquidatedValue.taxableIrppInterests - lifeInsuranceRebate
                            lifeInsuranceRebate -= (liquidatedValue.taxableIrppInterests - taxableInterests)
                            // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                            taxablesIrpp = taxableInterests
                            
                        case .pea:
                            // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                            taxablesIrpp = liquidatedValue.taxableIrppInterests
                            
                        case .other:
                            // part des produit de la liquidation inscrit en compte courant imposable à l'IRPP
                            taxablesIrpp = liquidatedValue.taxableIrppInterests
                    }
                    // populate prélèvements sociaux
                    socialTaxes = liquidatedValue.socialTaxes
                    
                    /// Versements annuels
                    // on compte quand même les versements de la dernière année
                    yearlyPayement = periodicInvestement.yearlyTotalPayement(atEndOf: year)
                }
            }
            // Adultes
        adultsRevenues: do {
            adultsRevenues
                .perCategory[.financials]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: adultsSaleValue.rounded()))
            adultsRevenues
                .perCategory[.financials]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: name,
                                   value: adultFraction * taxablesIrpp.rounded()))
            adultTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: adultFraction * socialTaxes.rounded()))
            investPayements
                .namedValues
                .append(NamedValue(name : name,
                                   value: yearlyPayement.rounded()))
        }
        childrenRevenues: do {
            // Enfants
            childrenRevenues
                .perCategory[.financials]?
                .credits
                .namedValues
                .append(NamedValue(name: name,
                                   value: childrenSaleValue.rounded()))
            childrenRevenues
                .perCategory[.financials]?
                .taxablesIrpp
                .namedValues
                .append(NamedValue(name: name,
                                   value: (1.0 - adultFraction) * taxablesIrpp.rounded()))
            childrenTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: (1.0 - adultFraction) * socialTaxes.rounded()))
        }
        }
    }
}
