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

extension CashFlowLine {
    /// Gère le produit de la vente des investissements financiers périodiques + les versements périodiques à réaliser
    /// - Note:
    ///  - le produit de la vente se répartit entre UF et NP en cas de démembrement
    ///  - le produit de la vente est réinvesti dans des actifs détenus par le(s) récipiendaire(s)
    ///  - il ne doit donc pas être incorporés au NetCashFlow de fin d'année à ré-investir en fin d'année
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    mutating func managePeriodicInvestmentRevenues(of patrimoine       : Patrimoin,
                                                   for adultsName      : [String],
                                                   lifeInsuranceRebate : inout Double) {
        // pour chaque investissement financier periodique
        for periodicInvestement in patrimoine.assets.periodicInvests.items.sorted(by:<) {
            let name = periodicInvestement.name
            var revenue        : Double = 0
            var taxablesIrpp   : Double = 0
            var socialTaxes    : Double = 0
            var yearlyPayement : Double = 0

            if periodicInvestement.isPartOfPatrimoine(of: adultsName) {
                /// Ventes de l'année
                // le crédit se fait au début de l'année qui suit la vente
                let liquidatedValue = periodicInvestement.liquidatedValue(atEndOf: year - 1)
                // produit de la liquidation inscrit en compte courant avant prélèvements sociaux et IRPP
                revenue = liquidatedValue.revenue
                // créditer le produit de la vente sur les comptes des personnes
                // en fonction de leur part de propriété respective
                let ownedSaleValues = periodicInvestement.ownedValues(ofValue          : liquidatedValue.revenue,
                                                                      atEndOf          : year,
                                                                      evaluationMethod : .patrimoine)
                let netCashFlowManager = NetCashFlowManager()
                netCashFlowManager.investCapital(ownedCapitals : ownedSaleValues,
                                                 in            : patrimoine,
                                                 atEndOf       : year)
                
                // populate plus values taxables à l'IRPP
                switch periodicInvestement.type {
                    case .lifeInsurance:
                        var taxableInterests: Double
                        // apply rebate if some is remaining
                        taxableInterests = zeroOrPositive(liquidatedValue.taxableIrppInterests - lifeInsuranceRebate)
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
            
            adultsRevenues.perCategory[.financials]?.credits.namedValues
                .append((name: name,
                         value: revenue.rounded()))
            adultsRevenues.perCategory[.financials]?.taxablesIrpp.namedValues
                .append((name: name,
                         value: taxablesIrpp.rounded()))
            adultTaxes.perCategory[.socialTaxes]?.namedValues
                .append((name: name,
                         value: socialTaxes.rounded()))
            investPayements.namedValues
                .append((name : name,
                         value: yearlyPayement.rounded()))
        }
    }
}
