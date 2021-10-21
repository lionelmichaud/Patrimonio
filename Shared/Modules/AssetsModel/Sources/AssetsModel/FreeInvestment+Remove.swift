//
//  FreeInvestment+Remove.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/07/2021.
//

import Foundation
import os
import Ownership

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.FreeInvestement.remove")

extension FreeInvestement {
    func withdrawal(netAmount        : Double,
                    maxPermitedValue : Double)
    -> (brutAmount       : Double,
        brutAmountSplit  : (investement: Double, interest: Double),
        revenue          : Double,
        interests        : Double,
        netInterests     : Double,
        taxableInterests : Double,
        socialTaxes      : Double) {
        var revenue = netAmount
        var brutAmount       : Double
        var brutAmountSplit  : (investement  : Double, interest  : Double)
        var netInterests     : Double // intérêts nets de charges sociales
        var taxableInterests : Double // part imposable à l'IRPP des intérêts nets de charges sociales
        var socialTaxes      : Double // charges sociales sur les intérêts
        
        switch type {
            case .lifeInsurance(let periodicSocialTaxes, _):
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = (periodicSocialTaxes ? netAmount : FreeInvestement.fiscalModel.financialRevenuTaxes.brut(netAmount))
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > maxPermitedValue {
                    brutAmount = maxPermitedValue
                    revenue    = (periodicSocialTaxes ? brutAmount : FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmount))
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                if periodicSocialTaxes {
                    netInterests = brutAmountSplit.interest
                    socialTaxes  = 0.0
                } else {
                    netInterests = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmountSplit.interest)
                    socialTaxes  = FreeInvestement.fiscalModel.financialRevenuTaxes.socialTaxes(brutAmountSplit.interest)
                }
                // Assurance vie: les plus values sont imposables à l'IRPP (mais avec une franchise applicable à la totalité des interets retirés dans l'année: calculé ailleurs)
                taxableInterests = netInterests
                
            case .pea:
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = FreeInvestement.fiscalModel.financialRevenuTaxes.brut(netAmount)
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > maxPermitedValue {
                    brutAmount = maxPermitedValue
                    revenue    = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmount)
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                netInterests = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmountSplit.interest)
                socialTaxes  = FreeInvestement.fiscalModel.financialRevenuTaxes.socialTaxes(brutAmountSplit.interest)
                // PEA: les plus values ne sont pas imposables à l'IRPP
                taxableInterests = 0.0
                
            case .other:
                // montant brut à retirer pour obtenir le montant net souhaité
                brutAmount = FreeInvestement.fiscalModel.financialRevenuTaxes.brut(netAmount)
                // on ne peut pas retirer plus que la capital présent
                if brutAmount > maxPermitedValue {
                    brutAmount = maxPermitedValue
                    revenue    = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmount)
                }
                // parts d'intérêt et de capital contenues dans le brut retiré
                brutAmountSplit = split(removal: brutAmount)
                // intérêts nets de charges sociales
                netInterests = FreeInvestement.fiscalModel.financialRevenuTaxes.net(brutAmountSplit.interest)
                socialTaxes  = FreeInvestement.fiscalModel.financialRevenuTaxes.socialTaxes(brutAmountSplit.interest)
                // autre cas: les plus values sont totalement imposables à l'IRPP
                taxableInterests = netInterests
        }
        return (brutAmount       : brutAmount,
                brutAmountSplit  : brutAmountSplit,
                revenue          : revenue,
                interests        : brutAmountSplit.interest,
                netInterests     : netInterests,
                taxableInterests : taxableInterests,
                socialTaxes      : socialTaxes)
    }
    
    /// Effectuer un retrait de `netAmount` NET de charges sociales pour le compte d'un débiteur nommé `name`.
    /// - Note:
    ///     Si `name` = "" : on retire le montant indépendament de tout droit de propriété
    ///
    ///     Si `name` != "" : on tient compte des droit de propriété de `name` sur le bien:
    ///     - Le retrait n'est alors autorisé que si `name` possède une part de la PP du bien.
    ///     - Autorise le retrait dans la limite de la part de propriété de `name`.
    ///     - Met à jour la part de propriété de `name` en conséquence.
    /// - Returns:
    ///     - revenue: retrait net de charges sociales réellement obtenu (= netAmount si le capital est suffisant, moins sinon)
    ///     - interests: intérêts bruts avant charges sociales
    ///     - netInterests: intérêts nets de charges sociales
    ///     - taxableInterests: part des netInterests imposable à l'IRPP
    ///     - socialTaxes: charges sociales sur les intérêts
    /// - Parameters:
    ///   - netAmount: retrait net de charges sociales souhaité
    ///   - name: nom du débiteur ou nil
    public mutating func withdrawal(netAmount : Double,
                                    for name  : String = "")
    -> (revenue          : Double,
        interests        : Double,
        netInterests     : Double,
        taxableInterests : Double,
        socialTaxes      : Double) {
        let zero = (revenue          : 0.0,
                    interests        : 0.0,
                    netInterests     : 0.0,
                    taxableInterests : 0.0,
                    socialTaxes      : 0.0)
        
        guard currentState.value > 0.0 else {
            // le compte est vide: on ne retire rien
            return zero
        }
        
        let (checkOwnership, isAUsufructOwner, isAfullOwner, isTheUniqueFullOwner) =
            (name != "",
             ownership.hasAnUsufructOwner(named: name),
             ownership.hasAFullOwner(named: name),
             ownership.hasAUniqueFullOwner(named: name))
        
        let updateOwnership  : Bool
        let updateInterests  : Bool
        let maxPermitedValue : Double
        var ownedValueBefore : Double            = 0
        var theOwnedValues   : NameValueDico = [:]
        
        switch (checkOwnership, isAUsufructOwner, isAfullOwner, isTheUniqueFullOwner) {
            case (false, _, _, _):
                // on ne tient pas compte des droits de propriété de `name` sur le bien
                updateOwnership  = false
                updateInterests  = false
                maxPermitedValue = currentState.value
                
            case (true, true, _, _):
                // on doit tenir compte des droits de propriété de `name` sur le bien
                // Le bien est démembré et 'name' est un des UF
                guard let interest = cumulatedInterestsAfterSuccession else {
                    // il n'y pas d'intérêts à retirer de ce bien
                    return zero
                }
                updateOwnership = false
                updateInterests = true
                // part d'intérêts annuel qui revient à `name` compte tenu de sa part d'UF
                // c'est le montant maximum du retrait de cash possible en fin d'année
                maxPermitedValue = ownership.ownedRevenue(by        : name,
                                                          ofRevenue : interest)
                
            case (true, _, true, false):
                // on doit tenir compte des droits de propriété de `name` sur le bien
                // Le bien n'est PAS démembré et 'name' est un DES PP
                updateOwnership = true
                updateInterests = false
                // 'name' n'est pas le seul PP du bien => il faudra actualiser sa part de propriété
                theOwnedValues = ownedValues(atEndOf           : currentState.year,
                                             evaluationContext : .patrimoine)
                ownedValueBefore = theOwnedValues[name]!
                maxPermitedValue = min(currentState.value,
                                       ownedValueBefore)
                
            case (true, _, _, true):
                // on doit tenir compte des droits de propriété de `name` sur le bien
                // Le bien n'est PAS démembré et 'name' est un le SEUL PP
                updateOwnership  = false
                updateInterests  = false
                maxPermitedValue = currentState.value
                
            case (true, false, false, _):
                // on doit tenir compte des droits de propriété de `name` sur le bien
                // 'name' n'est ni UF ni PP => on ne peut pas effectuer de retrait de cash
                return zero
                
            default:
                customLog.log(level: .error,
                              "FreeInvestementError.remove: cas non prévu")
                return zero
        }
        
        guard maxPermitedValue > 0 else {
            return zero
        }
        
        let _removal = withdrawal(netAmount: netAmount, maxPermitedValue: maxPermitedValue)
        
        // décrémenter les intérêts et le capital
        if _removal.brutAmount == currentState.value {
            // On a vidé le compte: mettre précisément le compte à 0.0 (attention à l'arrondi sinon)
            currentState.interest   = 0
            currentState.investment = 0
        } else {
            // décrémenter le capital (versement et intérêts) du montant brut retiré pour obtenir le net (de charges sociales) souhaité
            currentState.interest   -= _removal.brutAmountSplit.interest
            currentState.investment -= _removal.brutAmountSplit.investement
        }
        
        // actualiser les intérêts cumulés depuis la transmission compte tenu de ce qui vient d'être retiré
        if updateInterests {
            currentInterestsAfterTransmission?.interest -= _removal.brutAmount
        }
        
        // actualiser les droits de propriété en tenant compte du retrait qui va être fait
        if updateOwnership {
            let ownedValueAfter = ownedValueBefore - _removal.brutAmount
            print("Avant   = \(ownedValueBefore.k€String)")
            print("Retrait = \(_removal.brutAmount.k€String)")
            print("Après   = \(ownedValueAfter.k€String)")
            print("Ownership avant = \n", String(describing: ownership))
            theOwnedValues[name] = ownedValueAfter
            ownership.fullOwners = []
            theOwnedValues.forEach { (name: String, value: Double) in
                ownership.fullOwners.append(Owner(name     : name,
                                                  fraction : value / currentState.value * 100.0))
            }
            print("Ownership après = \n", String(describing: ownership))
        }
        
        return (revenue          : _removal.revenue,
                interests        : _removal.brutAmountSplit.interest,
                netInterests     : _removal.netInterests,
                taxableInterests : _removal.taxableInterests,
                socialTaxes      : _removal.socialTaxes)
    }
}
