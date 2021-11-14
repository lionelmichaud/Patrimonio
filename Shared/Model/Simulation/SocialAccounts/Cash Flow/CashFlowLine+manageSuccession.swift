//
//  CashFlowLine+manageSuccession.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 12/07/2021.
//

import Foundation
import Persistence
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
        // créer le manager délégué
        var successionManager = SuccessionManager(with           : patrimoine,
                                                  using          : fiscalModel,
                                                  atEndOf        : year,
                                                  familyProvider : familyProvider,
                                                  run            : run)

        /// Gérer les succession de l'année
        successionManager.manageSuccessions(verbose: false)

        /// Incorporation des successions au CashFlow de l'année
        /// Récupérer les Successions de l'année pour le Cash-Flow de l'année
        legalSuccessions   += successionManager.legal.successions
        lifeInsSuccessions += successionManager.lifeInsurance.successions

        /// Revenus bruts des successions LEGALES
        //   - pour les adultes
        adultsRevenues
            .perCategory[.legalSuccession]?
            .credits
            .namedValues += successionManager.legal.revenuesAdults
        //   - pour les enfants
        childrenRevenues
            .perCategory[.legalSuccession]?
            .credits
            .namedValues += successionManager.legal.revenuesChildren
        
        /// Revenus bruts des transmissions d'ASSURANCES VIES
        //   - pour les adultes
        adultsRevenues
            .perCategory[.liSuccession]?
            .credits
            .namedValues += successionManager.lifeInsurance.revenuesAdults
        //   - pour les enfants
        childrenRevenues
            .perCategory[.liSuccession]?
            .credits
            .namedValues += successionManager.lifeInsurance.revenuesChildren
        
        /// Droits de successions LEGAUX
        //   - imputables aux adultes (= 0 puisque le conjoint survivant est exonéré)
        adultTaxes
            .perCategory[.legalSuccession]?
            .namedValues += successionManager.legal.taxesAdults
        //   - imputables aux enfants (doit être prélevé sur l'héritage après transfert de propriété)
        childrenTaxes
            .perCategory[.legalSuccession]?
            .namedValues += successionManager.legal.taxesChildren

        /// Droits de transmission des ASSURANCES VIES
        //   - imputables aux adultes (= 0 puisque le conjoint survivant est exonéré)
        adultTaxes
            .perCategory[.liSuccession]?
            .namedValues += successionManager.lifeInsurance.taxesAdults
        //   - imputables aux enfants
        childrenTaxes
            .perCategory[.liSuccession]?
            .namedValues += successionManager.lifeInsurance.taxesChildren
    }
}
