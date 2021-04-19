//
//  Adult+Unemployement.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 13/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import UnemployementModel

// MARK: - EXTENSION: Chômage
extension Adult {
    // MARK: - Computed Properties

    var SJR: Double { // computed
        guard let workIncome = workIncome else {
            return 0.0
        }
        switch workIncome {
            case .salary:
                // base: salaire brut
                return workBrutIncome / 365.0
            case .turnOver:
                return 0.0
        }
    }
    var hasUnemployementAllocationPeriod      : Bool { // computed
        guard let workIncome = workIncome else {
            return false
        }
        switch workIncome {
            case .turnOver:
                // pas d'allocation pour les non salariés
                return false
            case .salary:
                // pour les salariés, allocation seulement pour certaines causes de départ
                return Unemployment.canReceiveAllocation(for: causeOfRetirement)
        }
    } // computed
    var layoffCompensationBrutLegal           : Double? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let workIncome = workIncome else {
            return nil
        }
        switch workIncome {
            case .salary(_, _, _, let fromDate, _):
                let nbYearsSeniority = numberOf(.year,
                                                from : fromDate,
                                                to   : dateOfRetirement).year!
                return Unemployment.model.indemniteLicenciement.layoffCompensationLegal(
                    yearlyWorkIncomeBrut : workBrutIncome,
                    nbYearsSeniority     : nbYearsSeniority)
            default:
                fatalError()
        }
    } // computed
    var layoffCompensationBrutConvention      : Double? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let workIncome = workIncome else {
            return nil
        }
        switch workIncome {
            case .salary(_, _, _, let fromDate, _):
                let nbYearsSeniority = numberOf(.year,
                                                from : fromDate,
                                                to   : dateOfRetirement).year!
                // base: salaire brut
                return Unemployment.model.indemniteLicenciement.layoffCompensation(
                    actualCompensationBrut : nil,
                    causeOfRetirement      : causeOfRetirement,
                    yearlyWorkIncomeBrut   : workBrutIncome,
                    age                    : age(atDate: dateOfRetirement).year!,
                    nbYearsSeniority       : nbYearsSeniority).brut
            default:
                fatalError()
        }
    } // computed
    var layoffCompensation                    : (nbMonth: Double, brut: Double, net: Double, taxable: Double)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let workIncome = workIncome else {
            return nil
        }
        switch workIncome {
            case .salary(_, _, _, let fromDate, _):
                let nbYearsSeniority = numberOf(.year,
                                                from : fromDate,
                                                to   : dateOfRetirement).year!
                // base: salaire brut
                return Unemployment.model.indemniteLicenciement.layoffCompensation(
                    actualCompensationBrut : layoffCompensationBonified,
                    causeOfRetirement      : causeOfRetirement,
                    yearlyWorkIncomeBrut   : workBrutIncome,
                    age                    : age(atDate: dateOfRetirement).year!,
                    nbYearsSeniority       : nbYearsSeniority)
            default:
                fatalError()
        }
    } // computed
    var unemployementAllocationDiffere        : Int? { // en jours
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let compensationSupralegal = layoffCompensation?.brut - layoffCompensationBrutLegal else {
            return nil
        }
        //Swift.print("supralégal = \(compensationSupralegal)")
        return Unemployment.model.allocationChomage.differeSpecifique(
            compensationSupralegal : compensationSupralegal,
            causeOfUnemployement   : causeOfRetirement)
    } // computed
    var unemployementAllocationDuration       : Int? { // en mois
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        return Unemployment.model.allocationChomage.durationInMonth(age: age(atDate: dateOfRetirement).year!)
    } // computed
    var dateOfStartOfUnemployementAllocation  : Date? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        return unemployementAllocationDiffere!.days.from(dateOfRetirement)!
    } // computed
    var dateOfStartOfAllocationReduction      : Date? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let reductionAfter = Unemployment.model.allocationChomage.reductionAfter(
                age: age(atDate: dateOfRetirement).year!,
                SJR: SJR) else {
            return nil
        }
        guard let dateOfStart = dateOfStartOfUnemployementAllocation else {
            return nil
        }
        return reductionAfter.months.from(dateOfStart)!
    } // computed
    var dateOfEndOfUnemployementAllocation    : Date? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        guard let dateOfStart = dateOfStartOfUnemployementAllocation else {
            return nil
        }
        return unemployementAllocationDuration!.months.from(dateOfStart)!
    } // computed
    var unemployementAllocation               : (brut: Double, net: Double)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        let dayly = Unemployment.model.allocationChomage.daylyAllocBeforeReduction(SJR: SJR)
        return (brut: dayly.brut * 365, net: dayly.net * 365)
    } // computed
    var unemployementReducedAllocation        : (brut: Double, net: Double)? { // computed
        guard let alloc = unemployementAllocation else {
            return nil
        }
        let reduc = unemployementAllocationReduction!
        return (brut: alloc.brut * (1 - reduc.percentReduc / 100),
                net : alloc.net  * (1 - reduc.percentReduc / 100))
    } // computed
    var unemployementTotalAllocation          : (brut: Double, net: Double)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        let totalDuration = unemployementAllocationDuration!
        let alloc         = unemployementAllocation!
        let allocReduite  = unemployementReducedAllocation!
        if let afterMonth = unemployementAllocationReduction!.afterMonth {
            return (brut: alloc.brut / 12 * afterMonth.double() + allocReduite.brut / 12 * (totalDuration - afterMonth).double(),
                    net : alloc.net  / 12 * afterMonth.double() + allocReduite.net  / 12 * (totalDuration - afterMonth).double())
        } else {
            return (brut: alloc.brut / 12 * totalDuration.double(),
                    net : alloc.net  / 12 * totalDuration.double())
        }
    } // computed
    var unemployementAllocationReduction      : (percentReduc: Double, afterMonth: Int?)? { // computed
        guard hasUnemployementAllocationPeriod else {
            return nil
        }
        return Unemployment.model.allocationChomage.reduction(age        : age(atDate: dateOfRetirement).year!,
                                                              daylyAlloc : unemployementAllocation!.brut / 365)
    } // computed

    // MARK: - Methods

    /// true si est vivant à la fin de l'année et année égale ou postérieur à l'année de cessation d'activité et égale ou inférieure à l'année de fin de droit d'allocation chomage
    /// - Parameter year: année
    func isReceivingUnemployementAllocation(during year: Int) -> Bool {
        guard isRetired(during: year) else {
            return false
        }
        guard let startDate = dateOfStartOfUnemployementAllocation,
              let endDate   = dateOfEndOfUnemployementAllocation else {
            return false
        }
        return (startDate.year...endDate.year).contains(year)
    }
    
    /// Allocation chômage perçue dans l'année
    /// - Parameter year: année
    /// - Returns: Allocation chômage perçue dans l'année brute, nette de charges sociales, taxable à l'IRPP
    func unemployementAllocation(during year: Int) -> BrutNetTaxable {
        guard isReceivingUnemployementAllocation(during: year) else {
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        let firstYearDay = firstDayOf(year : year)
        let lastYearDay  = lastDayOf(year  : year)
        let alloc        = unemployementAllocation!
        let dateDebAlloc = dateOfStartOfUnemployementAllocation!
        let dateFinAlloc = dateOfEndOfUnemployementAllocation!
        if let dateReducAlloc = dateOfStartOfAllocationReduction {
            // reduction d'allocation après un certaine date
            let allocReduite  = unemployementReducedAllocation!
            // intersection de l'année avec la période taux plein
            var debut   = max(dateDebAlloc, firstYearDay)
            var fin     = min(dateReducAlloc, lastYearDay)
            let nbDays1 = zeroOrPositive(numberOfDays(from : debut, to : fin).day!)
            // intersection de l'année avec la période taux réduit
            debut       = max(dateReducAlloc, firstYearDay)
            fin         = min(dateFinAlloc, lastYearDay)
            let nbDays2 = zeroOrPositive(numberOfDays(from : debut, to : fin).day!)
            // somme des deux parties
            let brut = alloc.brut/365 * nbDays1.double() +
                allocReduite.brut/365 * nbDays2.double()
            let net = alloc.net/365  * nbDays1.double() +
                allocReduite.net/365 * nbDays2.double()
            return BrutNetTaxable(brut    : brut,
                                  net     : net,
                                  taxable : net)
            
        } else {
            // pas de réduction d'allocation
            var nbDays: Int
            // nombre de jours d'allocation dans l'année
            if year == dateDebAlloc.year {
                // première année d'allocation
                nbDays = 365 - dateDebAlloc.dayOfYear!
            } else if year == dateFinAlloc.year {
                // dernière année d'allocation
                nbDays = dateFinAlloc.dayOfYear!
            } else {
                // année pleine
                nbDays = 365
            }
            let brut = alloc.brut/365 * nbDays.double()
            let net  = alloc.net/365  * nbDays.double()
            return BrutNetTaxable(brut    : brut,
                                  net     : net,
                                  taxable : net)
        }
    }
    
    /// Indemnité de licenciement perçue dans l'année
    /// - Parameter year: année
    /// - Returns: Indemnité de licenciement perçue dans l'année brute, nette de charges sociales, taxable à l'IRPP
    /// - Note: L'indemnité de licenciement est due m^me si le licencié est décédé pendant le préavis
    func layoffCompensation(during year: Int) -> BrutNetTaxable {
        guard year == dateOfRetirement.year else {
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        // on est bien dans l'année de cessation d'activité
        guard isAlive(atEndOf: year-1) else {
            // la personne n'était plus vivante l'année précédent son licenciement
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
        // la personne était encore vivante l'année précédent son licenciement
        if let layoffCompensation = layoffCompensation {
            return BrutNetTaxable(brut    : layoffCompensation.brut,
                                  net     : layoffCompensation.net,
                                  taxable : layoffCompensation.taxable)
        } else {
            // pas droit à une indemnité
            return BrutNetTaxable(brut: 0, net: 0, taxable: 0)
        }
    }
}
