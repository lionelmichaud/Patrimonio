//
//  CashFlowLine+manageSuccession.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/07/2021.
//

import Foundation
import FiscalModel
import PersonModel
import PatrimoineModel
import FamilyModel
import SuccessionManager

extension CashFlowLine {

    /// Gérer les succession de l'année.
    ///
    /// Identifier toutes les successions de l'année.
    ///
    /// Calculer les droits de succession des personnes décédées dans l'année.
    ///
    /// Transférer les biens des personnes décédées dans l'année vers ses héritiers.
    ///
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    ///   - fiscalModel: modèle fiscal
    mutating func manageSuccession(run               : Int,
                                   with patrimoine   : Patrimoin,
                                   familyProvider    : FamilyProviderP,
                                   using fiscalModel : Fiscal.Model) {
        var successionManager = SuccessionManager(with           : patrimoine,
                                                  using          : fiscalModel,
                                                  atEndOf        : year,
                                                  familyProvider : familyProvider,
                                                  run            : run)

        successionManager.manageSuccession()

        legalSuccessions   += successionManager.legalSuccessions
        lifeInsSuccessions += successionManager.lifeInsSuccessions

        // droits de successions légales
        //   - imputables aux adultes
        adultTaxes
            .perCategory[.legalSuccession]?
            .namedValues += successionManager.legalSuccessionsTaxesAdults
        //   - imputables aux enfants
        childrenTaxes
            .perCategory[.legalSuccession]?
            .namedValues += successionManager.legalSuccessionsTaxesChildren

        // droits de successions légales
        //   - imputables aux adultes
        adultTaxes
            .perCategory[.liSuccession]?
            .namedValues += successionManager.lifeInsSuccessionsTaxesAdults
        //   - imputables aux enfants
        childrenTaxes
            .perCategory[.liSuccession]?
            .namedValues += successionManager.lifeInsSuccessionsTaxesChildren
    }
}
