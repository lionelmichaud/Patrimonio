import Foundation
import os
import FiscalModel
import NamedValue
//import Disk

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CashFlow")

// MARK: - Ligne de cash flow annuel

struct CashFlowLine {
    
    // MARK: - nested types
    
    // agrégat des ages
    struct AgeTable {
        
        // properties
        
        var persons = [(name: String, age: Int)]()
        
        // methods
    }
    
    // MARK: - properties
    
    let year            : Int
    var ages            = AgeTable()
    // les comptes annuels de la SCI
    let sciCashFlowLine : SciCashFlowLine
    // revenus
    var taxableIrppRevenueDelayedToNextYear = Debt(name: "REVENU IMPOSABLE REPORTE A L'ANNEE SUIVANTE", note: "", value: 0)
    var revenues        = ValuedRevenues(name: "REVENUS HORS SCI")
    var sumOfRevenuesSalesExcluded: Double {
        revenues.totalRevenueSalesExcluded +
            sciCashFlowLine.netRevenuesSalesExcluded
    }
    var sumOfRevenues: Double {
        revenues.totalRevenue +
            sciCashFlowLine.netRevenues
    }
    // dépenses
    var taxes           = ValuedTaxes(name: "Taxes")
    var lifeExpenses    = NamedValueTable(tableName: "Dépenses de vie")
    var debtPayements   = NamedValueTable(tableName: "Remb. dette")
    var investPayements = NamedValueTable(tableName: "Investissements")
    var sumOfExpenses: Double {
        taxes.total +
            lifeExpenses.total +
            debtPayements.total +
            investPayements.total
    }
    // les successions légales survenues dans l'année
    var successions     : [Succession] = []
    // les transmissions d'assurances vie survenues dans l'année
    var lifeInsSuccessions : [Succession] = []
    
    // solde net des revenus courants communs - dépenses communes (hors ventes de bien en séparation de bien)
    var netCashFlowSalesExcluded: Double {
        sumOfRevenuesSalesExcluded - sumOfExpenses
    }

    // solde net de tous les revenus - dépenses (y.c. ventes de bien en séparation de bien))
    var netCashFlow: Double {
        sumOfRevenues - sumOfExpenses
    }

    // MARK: - initialization
    
    /// Création et peuplement d'un année de Cash Flow
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - year: année
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    ///   - taxableIrppRevenueDelayedFromLastyear: revenus taxable à l'IRPP en report d'imposition de l'année précédente
    /// - Throws: Si pas assez de capital -> `CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)`
    init(run                                   : Int,
         withYear       year                   : Int,
         withFamily     family                 : Family,
         withPatrimoine patrimoine             : Patrimoin,
         taxableIrppRevenueDelayedFromLastyear : Double) throws {
        self.year = year
        let adultsNames = family.adults.compactMap {
            $0.isAlive(atEndOf: year) ? $0.displayName : nil
        }
        revenues.taxableIrppRevenueDelayedFromLastYear.setValue(to: taxableIrppRevenueDelayedFromLastyear)
        
        /// initialize life insurance yearly rebate on taxes
        // TODO: mettre à jour le model de défiscalisation Asurance Vie
        var lifeInsuranceRebate = Fiscal.model.lifeInsuranceTaxes.model.rebatePerPerson * family.nbOfAdultAlive(atEndOf: year).double()
        
        /// SCI: calculer le cash flow de la SCI
        sciCashFlowLine = SciCashFlowLine(withYear : year,
                                          of  : patrimoine,
                                          for : adultsNames)
        
        try autoreleasepool {
            /// INCOME: populate Ages and Work incomes
            populateIncomes(of: family)
            
            /// REAL ESTATE: populate produit de vente, loyers, taxes sociales et taxes locales des bien immobiliers
            manageRealEstateRevenues(of  : patrimoine,
                                     for : adultsNames)
            
            /// SCPI: populate produit de vente, dividendes, taxes sociales des SCPI
            manageScpiRevenues(of  : patrimoine,
                               for : adultsNames)
            
            /// PERIODIC INVEST: populate revenue, des investissements financiers périodiques
            managePeriodicInvestmentRevenues(of                  : patrimoine,
                                             for                 : adultsNames,
                                             lifeInsuranceRebate : &lifeInsuranceRebate)
            
            // Note: les intérêts des investissements financiers libres sont capitalisés
            // => ne génèrent des charges sociales et de l'IRPP qu'au moment des retraits ou de leur liquidation
            
            /// IRPP: calcule de l'impot sur l'ensemble des revenus
            computeIrpp(of: family)
            
            /// ISF: calcule de l'impot sur la fortune
            computeISF(with : patrimoine)

            /// EXPENSES: compute and populate family expenses
            lifeExpenses.namedValues = family.expenses.namedValueTable(atEndOf: year)
            
            /// LOAN: populate remboursement d'emprunts
            manageLoanCashFlow(for : adultsNames,
                               of  : patrimoine)
            
            /// SUCCESSIONS: Calcul des droits de successions légales et assurances vies + peuple les successions de l'année
            ///              Transférer les biens des personnes décédées dans l'année vers ses héritiers
            manageSuccession(run  : run,
                             of   : family,
                             with : patrimoine)
            
            /// FREE INVEST: populate revenue, des investissements financiers libres et investir/retirer le solde net du cash flow de l'année
            try manageYearlyNetCashFlow(of                  : patrimoine,
                                        for                 : adultsNames,
                                        lifeInsuranceRebate : &lifeInsuranceRebate)
        }
        #if DEBUG
        //Swift.print("Year = \(year), Revenus = \(sumOfrevenues), Expenses = \(sumOfExpenses), Net cash flow = \(netCashFlow)")
        #endif
    }
    
    // MARK: - methods
    
    fileprivate mutating func updateSuccessionsTaxes(successionLegalTax : Double,
                                                     successionLiTax    : Double) {
        taxes.perCategory[.succession]?.namedValues
            .append((name  : TaxeCategory.succession.rawValue,
                     value : successionLegalTax.rounded()))
        taxes.perCategory[.liSuccession]?.namedValues
            .append((name  : TaxeCategory.liSuccession.rawValue,
                     value : successionLiTax.rounded()))
    }
    
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
    fileprivate mutating func manageSuccession(run             : Int,
                                               of family       : Family,
                                               with patrimoine : Patrimoin) {
        // FIXME: - en fait il faudrait traiter les sucessions en séquences: calcul taxe => transmission puis calcul tax => transmission
        // identification des personnes décédées dans l'année
        let decedents = family.deceasedAdults(during: year)
        
        // ajouter les droits de succession (légales et assurances vie) aux taxes
        var totalLegalSuccessionTax = 0.0
        var totalLiSuccessionTax    = 0.0
        // pour chaque défunt
        decedents.forEach { decedent in
            SimulationLogger.shared.log(run: run,
                                        logTopic: .lifeEvent,
                                        message: "Décès de \(decedent.displayName) en \(year)")
            // calculer les droits de successions légales
            let legalSuccessionManager = LegalSuccessionManager()
            let succession =
                legalSuccessionManager.legalSuccession(in      : patrimoine,
                                                       of      : decedent,
                                                       atEndOf : year)
            successions.append(succession)
            totalLegalSuccessionTax += succession.tax
            
            // calculer les droits de transmission assurances vies
            let lifeInsuranceSuccessionManager = LifeInsuranceSuccessionManager()
            let liSuccession =
                lifeInsuranceSuccessionManager.lifeInsuraceSuccession(in      : patrimoine,
                                                                      of      : decedent,
                                                                      atEndOf : year)
            lifeInsSuccessions.append(liSuccession)
            totalLiSuccessionTax += liSuccession.tax
            
            // transférer les biens d'un défunt vers ses héritiers
            let ownershipManager = OwnershipManager()
            ownershipManager.transferOwnershipOf(of       : patrimoine,
                                                 decedent : decedent,
                                                 atEndOf  : year)
        }
        
        // mettre à jour les taxes de l'année avec les droits de successions de l'année
        updateSuccessionsTaxes(successionLegalTax : totalLegalSuccessionTax,
                               successionLiTax    : totalLiSuccessionTax)
    }
    
    fileprivate mutating func computeIrpp(of family: Family) {
        taxes.irpp = try! Fiscal.model.incomeTaxes.irpp(taxableIncome : revenues.totalTaxableIrpp,
                                                        nbAdults      : family.nbOfAdultAlive(atEndOf: year),
                                                        nbChildren    : family.nbOfFiscalChildren(during: year))
        taxes.perCategory[.irpp]?.namedValues.append((name  : TaxeCategory.irpp.rawValue,
                                                      value : taxes.irpp.amount.rounded()))
    }
    
    fileprivate mutating func computeISF(with patrimoine : Patrimoin) {
        let taxableAsset = patrimoine.realEstateValue(atEndOf          : year,
                                                      evaluationMethod : .ifi)
        taxes.isf = try! Fiscal.model.isf.isf(taxableAsset: taxableAsset)
        taxes.perCategory[.isf]?.namedValues.append((name  : TaxeCategory.isf.rawValue,
                                                     value : taxes.isf.amount.rounded()))
    }
    
    /// Populate remboursement d'emprunts des adultes de la famille
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   -  adultsName: les adultes dela famille
    fileprivate mutating func manageLoanCashFlow(for adultsName : [String],
                                                 of patrimoine  : Patrimoin) {
        for loan in patrimoine.liabilities.loans.items.sorted(by:<)
        where loan.isPartOfPatrimoine(of: adultsName) {
            let yearlyPayement = -loan.yearlyPayement(year)
            let name           = loan.name
            debtPayements.namedValues.append((name : name,
                                              value: yearlyPayement.rounded()))
        }
    }
    
    /// Gérer l'excédent ou le déficit de trésorierie (commune) en fin d'année
    ///
    /// - Warning:
    ///   On ne gère pas ici le ré-investissement des biens vendus dans l'année et détenus en propre.
    ///
    ///   Les produits de ventes de biens sont réinvestis au moment de la vente dans le patrimoine de ceux qui possèdente le bien (voir `investCapital`).
    ///
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    fileprivate mutating func manageYearlyNetCashFlow(of patrimoine       : Patrimoin,
                                                      for adultsName      : [String],
                                                      lifeInsuranceRebate : inout Double) throws {
        let netCashFlowManager       = NetCashFlowManager()
        let netCashFlowSalesExcluded = self.netCashFlowSalesExcluded
        
        // On ne gère pas ici le ré-investissement des biens vendus dans l'année et détenus en propre
        if netCashFlowSalesExcluded > 0.0 {
            // capitaliser les intérêts des investissements libres
            netCashFlowManager.capitalizeFreeInvestments(in      : patrimoine,
                                                         atEndOf : year)
            // ajouter le cash flow net à un investissement libre de type Assurance vie
            netCashFlowManager.investNetCashFlow(amount : netCashFlowSalesExcluded,
                                                 in     : patrimoine,
                                                 for    : adultsName)
            
        } else {
            // retirer le solde net d'un investissement libre: d'abord PEA ensuite Assurance vie
            // géré comme un revenu en report d'imposition (dette)
            let totalTaxableInterests =
                try netCashFlowManager.getCashFromInvestement(thisAmount          : -netCashFlowSalesExcluded,
                                                              in                  : patrimoine,
                                                              atEndOf             : year,
                                                              for                 : adultsName,
                                                              taxes               : &taxes.perCategory,
                                                              lifeInsuranceRebate : &lifeInsuranceRebate)
            taxableIrppRevenueDelayedToNextYear.increase(by: totalTaxableInterests.rounded())
            
            // capitaliser les intérêts des investissements libres
            netCashFlowManager.capitalizeFreeInvestments(in      : patrimoine,
                                                         atEndOf : year)
        }
    }
}

// MARK: - CashFlowLine extensions for VISITORS

extension CashFlowLine: CashFlowCsvVisitableP {
    func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension CashFlowLine: CashFlowLineChartVisitableP {
    func accept(_ visitor: CashFlowLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension CashFlowLine: CashFlowStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension CashFlowLine: CashFlowCategoryStackedBarChartVisitableP {
    func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}

extension CashFlowLine: CashFlowIrppVisitableP {
    func accept(_ visitor: CashFlowIrppVisitorP) {
        visitor.buildIrppChart(element: self)
    }
}

extension CashFlowLine: CashFlowIrppRateVisitableP {
    func accept(_ visitor: CashFlowIrppRateVisitorP) {
        visitor.buildIrppRateChart(element: self)
    }
}

extension CashFlowLine: CashFlowIsfVisitableP {
    func accept(_ visitor: CashFlowIsfVisitorP) {
        visitor.buildIsfChart(element: self)
    }
}
