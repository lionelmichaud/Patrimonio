import Foundation
import os
import FiscalModel
import NamedValue
//import Disk

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CashFlow")

// MARK: - Ligne de cash flow annuel

struct CashFlowLine {
    
    // MARK: - Nested types
    
    // agrégat des ages des membres de la famille pendant l'année en cours
    struct AgeTable {
        var persons = [(name: String, age: Int)]()
    }
    
    // MARK: - Properties
    
    let year : Int
    var ages = AgeTable()
    
    /// les comptes annuels de la SCI
    let sciCashFlowLine : SciCashFlowLine
    
    // Les comptes annuels des Parents
    
    // Revenus des Parents
    
    /// Profits des Parents en report d'imposition d'une année sur l'autre
    var taxableIrppRevenueDelayedToNextYear = Debt(name: "REVENU IMPOSABLE REPORTE A L'ANNEE SUIVANTE", note: "", value: 0)

    /// Agrégat des Revenus annuels des Parents (hors SCI)
    var adultsRevenues = ValuedRevenues(name: "REVENUS PARENTS HORS SCI")

    /// Total de tous les revenus nets de l'année des Parents, versé en compte courant
    ///  - avant taxes et impots
    ///  - inclus revenus de la SCI
    ///  - EXCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    ///
    /// Note: Utilisé pour calculer le Net Cash-Flow de fin d'année (à réinvestir en fin d'année)
    var sumOfRevenuesSalesExcluded: Double {
        adultsRevenues.totalRevenueSalesExcluded +
            sciCashFlowLine.netRevenuesSalesExcluded
    }

    /// Total de tous les revenus nets de l'année des Parents, versé en compte courant.
    /// - avant taxes et impots
    /// - inclus revenus de la SCI
    /// - INCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    var sumOfRevenues: Double {
        adultsRevenues.totalRevenue +
            sciCashFlowLine.netRevenues
    }
    
    // Dépenses des Parents
    
    /// Agrégat des Taxes annuelles payées par les Parents
    var adultTaxes      = ValuedTaxes(name: "Taxes")
    
    /// Dépenses de vie des Parents
    var lifeExpenses    = NamedValueTable(tableName: "Dépenses de vie")
    
    /// remboursements d'emprunts ou de dettes des Parents
    var debtPayements   = NamedValueTable(tableName: "Remb. dette")
    
    /// Versements périodiques des Parents sur des plan d'investissement périodiques
    var investPayements = NamedValueTable(tableName: "Investissements")
    
    /// Total des dépenses annuelles des Parents
    var sumOfExpenses: Double {
        adultTaxes.total +
            lifeExpenses.total +
            debtPayements.total +
            investPayements.total
    }
    
    // Soldes nets annuels (Revenus - Dépenses) des Parents
    
    /// Solde net des revenus - dépenses courants des Parents - dépenses communes (hors ventes de bien en séparation de bien)
    /// Solde net de tous les revenus - dépenses (y.c. ventes de bien en séparation de bien))
    /// - inclus revenus/dépenses de la SCI
    /// - EXCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    var netCashFlowSalesExcluded: Double {
        sumOfRevenuesSalesExcluded - sumOfExpenses
    }
    
    /// Solde net de tous les revenus - dépenses (y.c. ventes de bien en séparation de bien))
    /// - inclus revenus/dépenses de la SCI
    /// - INCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    var netCashFlow: Double {
        sumOfRevenues - sumOfExpenses
    }
    
    // Successions survenus dans l'année
    
    /// Les successions légales survenues dans l'année
    var successions        : [Succession] = []
    
    /// Les transmissions d'assurances vie survenues dans l'année
    var lifeInsSuccessions : [Succession] = []
    
    // MARK: - Initialization
    
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
        adultsRevenues.taxableIrppRevenueDelayedFromLastYear.setValue(to: taxableIrppRevenueDelayedFromLastyear)
        
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
    
    // MARK: - Methods
    
    fileprivate mutating func computeIrpp(of family: Family) {
        adultTaxes.irpp = try! Fiscal.model.incomeTaxes.irpp(taxableIncome : adultsRevenues.totalTaxableIrpp,
                                                        nbAdults      : family.nbOfAdultAlive(atEndOf: year),
                                                        nbChildren    : family.nbOfFiscalChildren(during: year))
        adultTaxes.perCategory[.irpp]?.namedValues.append((name  : TaxeCategory.irpp.rawValue,
                                                      value : adultTaxes.irpp.amount.rounded()))
    }
    
    fileprivate mutating func computeISF(with patrimoine : Patrimoin) {
        let taxableAsset = patrimoine.realEstateValue(atEndOf          : year,
                                                      evaluationMethod : .ifi)
        adultTaxes.isf = try! Fiscal.model.isf.isf(taxableAsset: taxableAsset)
        adultTaxes.perCategory[.isf]?.namedValues.append((name  : TaxeCategory.isf.rawValue,
                                                     value : adultTaxes.isf.amount.rounded()))
    }
    
    /// Populate remboursement d'emprunts des adultes de la famille
    /// - Parameters:
    ///   - patrimoine: du patrimoine
    ///   -  adultsName: les adultes dela famille
    fileprivate mutating func manageLoanCashFlow(for adultsName : [String],
                                                 of patrimoine  : Patrimoin) {
        for loan in patrimoine.liabilities.loans.items.sorted(by:<) {
            let name = loan.name
            if loan.isPartOfPatrimoine(of: adultsName) {
                let yearlyPayement = -loan.yearlyPayement(year)
                debtPayements.namedValues.append((name : name,
                                                  value: yearlyPayement.rounded()))
            } else {
                // pour garder le nombre de séries graphiques constant au cours du temps
                debtPayements.namedValues.append((name : name,
                                                  value: 0))
            }
        }
    }
    
    /// Gérer l'excédent ou le déficit de trésorierie (commune des Parents) en fin d'année
    ///
    /// - Warning:
    ///   On ne gère pas ici le ré-investissement des biens vendus dans l'année et détenus en propre.
    ///
    ///   Les produits de ventes de biens sont réinvestis au moment de la vente dans le patrimoine
    ///   de ceux qui possèdente le bien (voir `investCapital`).
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
        // c'est fait en amont au moment de la vente
        if netCashFlowSalesExcluded > 0.0 {
            // capitaliser les intérêts des investissements libres
            netCashFlowManager.capitalizeFreeInvestments(in      : patrimoine,
                                                         atEndOf : year)
            // ajouter le cash flow net à un investissement libre de type Assurance vie
            netCashFlowManager.investNetCashFlow(amount : netCashFlowSalesExcluded,
                                                 in     : patrimoine,
                                                 for    : adultsName)
            
        } else {
            // Retirer le solde net d'un investissement libre: d'abord PEA ensuite Assurance vie.
            // Les taxes dues au titre des retraits sont gérées comme un revenu en report d'imposition (dette).
            let totalTaxableInterests =
                try netCashFlowManager.getCashFromInvestement(thisAmount          : -netCashFlowSalesExcluded,
                                                              in                  : patrimoine,
                                                              atEndOf             : year,
                                                              for                 : adultsName,
                                                              taxes               : &adultTaxes.perCategory,
                                                              lifeInsuranceRebate : &lifeInsuranceRebate)
            taxableIrppRevenueDelayedToNextYear.increase(by: totalTaxableInterests.rounded())
            
            // capitaliser les intérêts des investissements libres après avoir effectué les retraits
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
