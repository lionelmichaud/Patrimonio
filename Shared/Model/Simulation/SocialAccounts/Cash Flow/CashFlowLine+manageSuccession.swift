//
//  CashFlowLine+manageSuccession.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/07/2021.
//

import Foundation
import ModelEnvironment
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
    mutating func manageSuccession(run             : Int,
                                   of family       : Family,
                                   with patrimoine : Patrimoin,
                                   using model     : Model) {
        var successionManager = SuccessionManager(with    : patrimoine,
                                                  using   : model,
                                                  atEndOf : year,
                                                  run     : run)

        successionManager.manageSuccession()

        legalSuccessions   += successionManager.legalSuccessions
        lifeInsSuccessions += successionManager.lifeInsSuccessions

        adultTaxes
            .perCategory[.legalSuccession]?
            .namedValues += successionManager.legalSuccessionsTaxes
        adultTaxes
            .perCategory[.liSuccession]?
            .namedValues += successionManager.lifeInsSuccessionsTaxes
    }
}
