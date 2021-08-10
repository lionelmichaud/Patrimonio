//
//  CashFlowLine+populateIncomes.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/04/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import ModelEnvironment
import PersonModel

extension CashFlowLine {
    /// Populate Ages and Work incomes
    /// - Parameter family: de la famille
    mutating func populateIncomes(of family   : Family,
                                  using model : Model) {
        var totalPensionDiscount = 0.0
        
        // pour chaque membre de la famille
        for person in family.members.items.sorted(by:>) {
            // populate ages of family members
            let name = person.name.familyName! + " " + person.name.givenName!
            ages.persons.append((name: name, age: person.age(atEndOf: year)))
            // populate work, pension and unemployement incomes of family members
            if let adult = person as? Adult {
                /// revenus du travail
                let workIncome = adult.workIncome(during: year, using: model)
                // revenus du travail inscrit en compte avant IRPP (net charges sociales, de dépenses de mutuelle ou d'assurance perte d'emploi)
                adultsRevenues.perCategory[.workIncomes]?.credits.namedValues
                    .append((name: name,
                             value: workIncome.net.rounded()))
                // part des revenus du travail inscrite en compte qui est imposable à l'IRPP
                adultsRevenues.perCategory[.workIncomes]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: workIncome.taxableIrpp.rounded()))
                
                /// pension de retraite
                let pension  = adult.pension(during: year, using: model)
                // pension inscrit en compte avant IRPP (net de charges sociales)
                adultsRevenues.perCategory[.pensions]?.credits.namedValues
                    .append((name: name,
                             value: pension.net.rounded()))
                // part de la pension inscrite en compte qui est imposable à l'IRPP
                let relicat = model.fiscalModel.pensionTaxes.model.maxRebate - totalPensionDiscount
                var discount = pension.net - pension.taxable
                if relicat >= discount {
                    // l'abattement est suffisant pour cette personne
                    adultsRevenues.perCategory[.pensions]?.taxablesIrpp.namedValues
                        .append((name: name,
                                 value: pension.taxable.rounded()))
                } else {
                    discount = relicat
                    adultsRevenues.perCategory[.pensions]?.taxablesIrpp.namedValues
                        .append((name: name,
                                 value: (pension.net - discount).rounded()))
                }
                totalPensionDiscount += discount
                
                /// indemnité de licenciement
                let compensation = adult.layoffCompensation(during: year, using: model)
                adultsRevenues.perCategory[.layoffCompensation]?.credits.namedValues
                    .append((name: name,
                             value: compensation.net.rounded()))
                adultsRevenues.perCategory[.layoffCompensation]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: compensation.taxable.rounded()))
                /// allocation chomage
                let alocation = adult.unemployementAllocation(during: year, using: model)
                adultsRevenues.perCategory[.unemployAlloc]?.credits.namedValues
                    .append((name: name, value: alocation.net.rounded()))
                adultsRevenues.perCategory[.unemployAlloc]?.taxablesIrpp.namedValues
                    .append((name: name,
                             value: alocation.taxable.rounded()))
            }
        }
    }
}
