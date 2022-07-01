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
import FiscalModel

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
                                                   lifeInsuranceRebate      : inout Double,
                                                   using fiscalModel        : Fiscal.Model) {
        // pour chaque investissement financier periodique
        for periodicInvestement in patrimoine.assets.periodicInvests.items.sorted(by:<) {
            let name = periodicInvestement.name
            var adultsSaleValue   : Double = 0
            var childrenSaleValue : Double = 0
            @ZeroOrPositive
            var taxablesFlatTaxParents  : Double = 0
            @ZeroOrPositive
            var taxablesFlatTaxChildren : Double = 0
            var flatTaxParents    : Double = 0
            var flatTaxChildren   : Double = 0
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

                    // populate plus values taxables à la flat taxe
                    switch periodicInvestement.type {
                        case .lifeInsurance:
                            // PARENTS
                            // part de plus-value des parents
                            let parentsTaxableInterestsShare = adultFraction * liquidatedValue.taxableIrppInterests
                            // Impôts: part des produit de la liquidation inscrit en compte courant imposable
                            //   apply rebate if some is remaining
                            taxablesFlatTaxParents = parentsTaxableInterestsShare - lifeInsuranceRebate
                            //   update rebate
                            lifeInsuranceRebate -= (parentsTaxableInterestsShare - taxablesFlatTaxParents)
                            
                            flatTaxParents = fiscalModel
                                .financialRevenuTaxes
                                .flatTax(plusValueTaxable: taxablesFlatTaxParents)

                            // ENFANTS
                            // part de plus-value des enfants
                            let childrenTaxableInterestsShare = (1.0 - adultFraction) * liquidatedValue.taxableIrppInterests
                            // Impôts: part des produit de la liquidation inscrit en compte courant imposable
                            //   apply rebate if some is remaining
                            // TODO: - appliquer l'abattement aux enfants
                            taxablesFlatTaxChildren = childrenTaxableInterestsShare
                            //   update rebate
                            // TODO: - mettre à jour l'abattement des enfants

                            flatTaxChildren = fiscalModel
                                .financialRevenuTaxes
                                .flatTax(plusValueTaxable: taxablesFlatTaxChildren)

                        case .pea:
                            // Impôts: les plus values PEA ne sont pas imposables
                            taxablesFlatTaxParents  = 0
                            taxablesFlatTaxChildren = 0

                            flatTaxParents  = 0
                            flatTaxChildren = 0

                        case .other:
                            // Impôts: part des produit de la liquidation inscrit en compte courant imposable
                            taxablesFlatTaxParents  = adultFraction * liquidatedValue.taxableIrppInterests
                            taxablesFlatTaxChildren = (1.0 - adultFraction) * liquidatedValue.taxableIrppInterests
                            
                            flatTaxParents = fiscalModel
                                .financialRevenuTaxes
                                .flatTax(plusValueTaxable: taxablesFlatTaxParents)
                            flatTaxChildren = fiscalModel
                                .financialRevenuTaxes
                                .flatTax(plusValueTaxable: taxablesFlatTaxChildren)
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
//            adultsRevenues
//                .perCategory[.financials]?
//                .taxablesIrpp
//                .namedValues
//                .append(NamedValue(name: name,
//                                   value: adultFraction * taxablesIrpp.rounded()))
           adultTaxes
                .perCategory[.flatTax]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: flatTaxParents.rounded()))
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
//            childrenRevenues
//                .perCategory[.financials]?
//                .taxablesIrpp
//                .namedValues
//                .append(NamedValue(name: name,
//                                   value: (1.0 - adultFraction) * taxablesFlatTaxParents.rounded()))
            childrenTaxes
                .perCategory[.flatTax]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: flatTaxChildren.rounded()))
            childrenTaxes
                .perCategory[.socialTaxes]?
                .namedValues
                .append(NamedValue(name: name,
                                   value: (1.0 - adultFraction) * socialTaxes.rounded()))
        }
        }
    }
}
