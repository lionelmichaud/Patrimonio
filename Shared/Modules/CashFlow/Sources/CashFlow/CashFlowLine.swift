import Foundation
import os
import AppFoundation
import NamedValue
import ModelEnvironment
import LifeExpense
import Succession
import Liabilities
import PatrimoineModel
import FamilyModel
import SuccessionManager

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.CashFlow")

/// Combinaisons possibles de séries sur le graphique de CashFlow
public enum CashCombination: String, PickableEnumP {
    case revenues = "Revenu"
    case expenses = "Dépense"
    case both     = "Tout"

    public var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Ligne de cash flow annuel

public struct CashFlowLine {
    
    // MARK: - Nested types
    
    // agrégat des ages des membres de la famille pendant l'année en cours
    struct AgeTable {
        var persons = [(name: String, age: Int)]()
    }
    
    // MARK: - Properties
    
    public let year : Int
    var ages = AgeTable()
    
    /// les comptes annuels de la SCI
    public let sciCashFlowLine : SciCashFlowLine
    
    // Les comptes annuels

    // MARK: -
    // Revenus
    
    /// Profits des Parents en report d'imposition d'une année sur l'autre
    public var taxableIrppRevenueDelayedToNextYear = Debt(name  : "REVENU IMPOSABLE REPORTE A L'ANNEE SUIVANTE",
                                                          note  : "",
                                                          value : 0)
    
    /// Agrégat des Revenus annuels des Parents (hors SCI)
    public var adultsRevenues = ValuedRevenues(name: "REVENUS PARENTS HORS SCI")
    
    /// Agrégat des Revenus annuels des Enfants
    public var childrenRevenues = ValuedRevenues(name: "REVENUS ENFANTS")
    
    /// Total de tous les revenus nets de l'année des Parents, versé en compte courant
    ///  - avant taxes et impots
    ///  - inclus revenus de la SCI
    ///  - EXCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    ///
    /// - Note: Utilisé pour calculer le Net Cash-Flow de fin d'année (à réinvestir en fin d'année)
    var sumOfAdultsRevenuesSalesExcluded: Double {
        adultsRevenues.totalRevenueSalesAndCapitalizedExcluded +
            sciCashFlowLine.netRevenuesSalesExcluded
    }
    
    /// Total de tous les revenus nets de l'année des Parents, versé en compte courant.
    /// - avant taxes et impots
    /// - inclus revenus de la SCI
    /// - INCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    public var sumOfAdultsRevenues: Double {
        adultsRevenues.totalRevenue +
            sciCashFlowLine.netRevenues
    }
    public var sumOfChildrenRevenues: Double {
        childrenRevenues.totalRevenue
    }

    // MARK: -
    // Dépenses
    
    /// Agrégat des Taxes annuelles payées par les Parents
    public var adultTaxes      = ValuedTaxes(name: "Taxes des parents")
    
    /// Agrégat des Taxes annuelles payées par les Enfants
    public var childrenTaxes   = ValuedTaxes(name: "Taxes des enfants")
    
    /// Dépenses de vie des Parents
    public var lifeExpenses    = NamedValueTable(tableName: "Dépenses de vie des parents")
    
    /// remboursements d'emprunts ou de dettes des Parents
    public var debtPayements   = NamedValueTable(tableName: "Remb. dette des parents")
    
    /// Versements périodiques des Parents sur des plan d'investissement périodiques
    public var investPayements = NamedValueTable(tableName: "Investissements des parents")
    
    /// Total des dépenses annuelles des Parents
    public var sumOfAdultsExpenses: Double {
        adultTaxes.total +
            lifeExpenses.total +
            debtPayements.total +
            investPayements.total
    }
    /// Total des dépenses annuelles des Enfants
    public var sumOfChildrenExpenses: Double {
        childrenTaxes.total
    }

    // MARK: -
    // Soldes nets annuels (Revenus - Dépenses) des Parents
    
    /// Solde net des revenus - dépenses courants des Parents - dépenses communes (hors ventes de bien en séparation de bien)
    /// Solde net de tous les revenus - dépenses (y.c. ventes de bien en séparation de bien))
    /// - inclus revenus/dépenses de la SCI
    /// - EXCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    var netAdultsCashFlowSalesExcluded: Double {
        sumOfAdultsRevenuesSalesExcluded - sumOfAdultsExpenses
    }
    
    /// Solde net de tous les revenus - dépenses (y.c. ventes de bien en séparation de bien))
    /// - inclus revenus/dépenses de la SCI
    /// - INCLUS les revenus capitalisés en cours d'année (produit de ventes, intérêts courants)
    public var netAdultsCashFlow: Double {
        sumOfAdultsRevenues - sumOfAdultsExpenses
    }
    public var netChildrenCashFlow: Double {
        sumOfChildrenRevenues - sumOfChildrenExpenses
    }

    // MARK: -
    // Successions survenus dans l'année
    
    /// Les successions légales survenues dans l'année
    public var legalSuccessions   : [Succession] = []
    
    /// Les transmissions d'assurances vie survenues dans l'année
    public var lifeInsSuccessions : [Succession] = []
    
    /// Solde net des héritages reçus par les enfants dans l'année
    public var netChildrenInheritances: [Double] = [] // un seul élément ou aucun
    
    // MARK: - Initialization
    
    public init() {
        year = CalendarCst.thisYear
        sciCashFlowLine = SciCashFlowLine()
    }
    
    /// Création et peuplement d'un année de Cash Flow
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - year: année
    ///   - family: la famille dont il faut faire le bilan
    ///   - expenses: dépenses de la famille
    ///   - patrimoine: le patrimoine de la famille
    ///   - taxableIrppRevenueDelayedFromLastyear: revenus taxable à l'IRPP en report d'imposition de l'année précédente
    ///   - previousSuccession: succession précédente pour les assuarnces vies
    ///   - model: le modèle à utiliser
    /// - Throws: Si pas assez de capital -> `CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)`
    public init(run                                   : Int,
                withYear       year                   : Int,
                withFamily     family                 : Family,
                withExpenses   expenses               : LifeExpensesDic,
                withPatrimoine patrimoine             : Patrimoin,
                taxableIrppRevenueDelayedFromLastyear : Double,
                previousSuccession                    : Succession?,
                using model                           : Model) throws {
        //        print(previousSuccession?.description)
        self.year = year
        let adultsNames   = family.adultsAliveName(atEndOf: year) ?? []
        let childrenNames = family.childrenAliveName(atEndOf: year) ?? []
        adultsRevenues
            .taxableIrppRevenueDelayedFromLastYear
            .setValue(to: taxableIrppRevenueDelayedFromLastyear)
        
        /// initialize life insurance yearly rebate on taxes
        // TODO: mettre à jour le model de défiscalisation Asurance Vie
        var lifeInsuranceRebate =
            model.fiscalModel
            .lifeInsuranceTaxes
            .model.rebatePerPerson * family.nbOfAdultAlive(atEndOf: year).double()
        
        /// SCI: calculer le cash flow de la SCI
        sciCashFlowLine = SciCashFlowLine(withYear : year,
                                          of       : patrimoine,
                                          for      : adultsNames,
                                          using    : model)
        
        try autoreleasepool {
            /// INCOME: populate Ages and Work incomes
            populateIncomes(of: family, using: model)
            
            /// REAL ESTATE: populate produit de vente, loyers, taxes sociales et taxes locales des bien immobiliers
            manageRealEstateRevenues(of          : patrimoine,
                                     forAdults   : adultsNames,
                                     forChildren : childrenNames)
            
            /// SCPI: populate produit de vente, dividendes, taxes sociales des SCPI
            manageScpiRevenues(of          : patrimoine,
                               forAdults   : adultsNames,
                               forChildren : childrenNames,
                               using       : model.fiscalModel)
            
            /// PERIODIC INVEST: populate revenue, des investissements financiers périodiques
            managePeriodicInvestmentRevenues(of                  : patrimoine,
                                             forAdults           : adultsNames,
                                             forChildren         : childrenNames,
                                             lifeInsuranceRebate : &lifeInsuranceRebate,
                                             using               : model.fiscalModel)
            
            // Note: les intérêts des investissements financiers libres sont capitalisés
            // => ne génèrent des charges sociales et de l'IRPP qu'au moment des retraits ou de leur liquidation
            
            /// Flat Tax: calcule de l'impot sur les plus-values
            computeFlatTax(of: family, using: model)

            /// IRPP: calcule de l'impot sur l'ensemble des revenus
            computeIrpp(of: family, using: model)
            
            /// ISF: calcule de l'impot sur la fortune
            computeISF(with: patrimoine, using: model)
            
            /// EXPENSES: compute and populate family expenses
            lifeExpenses.namedValues = expenses.namedValueTable(atEndOf: year)
            
            /// LOAN: populate remboursement d'emprunts
            manageLoanCashFlow(for: adultsNames, of: patrimoine)
            
            /// SUCCESSIONS: Calcul des droits de successions légales et assurances vies + peuple les successions de l'année
            ///              Transférer les biens des personnes décédées dans l'année vers ses héritiers
            manageSuccession(run                : run,
                             with               : patrimoine,
                             familyProvider     : family,
                             previousSuccession : previousSuccession,
                             using              : model.fiscalModel)
            
            /// FREE INVEST: populate revenue, des investissements financiers libres et investir/retirer le solde net du cash flow de l'année
            try manageAdultsYearlyNetCashFlow(of                  : patrimoine,
                                              forAdults           : adultsNames,
                                              lifeInsuranceRebate : &lifeInsuranceRebate)
        }
        #if DEBUG
        //Swift.print("Year = \(year), Revenus = \(sumOfrevenues), Expenses = \(sumOfExpenses), Net cash flow = \(netCashFlow)")
        #endif
    }
    
    // MARK: - Methods

    fileprivate mutating func computeFlatTax(of family   : Family,
                                             using model : Model) {
        // TODO: - calculer la flat tax sur les plus-values
    }
    
    fileprivate mutating func computeIrpp(of family   : Family,
                                          using model : Model) {
        // TODO: - il faudrait traiter différement les produits financiers en report d'imposition (flat taxe et non pas IRPP)
        adultTaxes.irpp = try! model.fiscalModel.incomeTaxes.irpp(taxableIncome : adultsRevenues.totalTaxableIrpp,
                                                                  nbAdults      : family.nbOfAdultAlive(atEndOf: year),
                                                                  nbChildren    : family.nbOfFiscalChildren(during: year))
        adultTaxes
            .perCategory[.irpp]?
            .namedValues
            .append(NamedValue(name  : TaxeCategory.irpp.rawValue,
                               value : adultTaxes.irpp.amount.rounded()))
    }
    
    fileprivate mutating func computeISF(with patrimoine : Patrimoin,
                                         using model     : Model) {
        let taxableAsset = patrimoine.realEstateValue(atEndOf           : year,
                                                      evaluationContext : .ifi)
        adultTaxes.isf = try! model.fiscalModel.isf.isf(taxableAsset: taxableAsset)
        adultTaxes
            .perCategory[.isf]?
            .namedValues
            .append(NamedValue(name  : TaxeCategory.isf.rawValue,
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
                debtPayements
                    .namedValues
                    .append(NamedValue(name : name,
                                       value: yearlyPayement.rounded()))
            } else {
                // pour garder le nombre de séries graphiques constant au cours du temps
                debtPayements
                    .namedValues
                    .append(NamedValue(name : name,
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
    ///   de ceux qui possèdent le bien (voir `investCapital`).
    ///
    /// - Parameters:
    ///   - patrimoine: patrimoine
    ///   - adultsName: des adultes
    ///   - lifeInsuranceRebate: franchise d'imposition sur les plus values
    /// - Throws: Si pas assez de capital -> CashFlowError.notEnoughCash(missingCash: amountRemainingToRemove)
    fileprivate mutating func manageAdultsYearlyNetCashFlow(of patrimoine        : Patrimoin,
                                                            forAdults adultsName : [String],
                                                            lifeInsuranceRebate  : inout Double) throws {
        let netCashFlowManager       = NetCashFlowManager()
        let netCashFlowSalesExcluded = self.netAdultsCashFlowSalesExcluded
        
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
            // Les plus-values des retraits sont gérées comme un revenu en report d'imposition IRPP (dette).
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
    public func accept(_ visitor: CashFlowCsvVisitorP) {
        visitor.buildCsv(element: self)
    }
}

extension CashFlowLine: CashFlowLineChartVisitableP {
    public func accept(_ visitor: CashFlowLineChartVisitorP) {
        visitor.buildLineChart(element: self)
    }
}

extension CashFlowLine: CashFlowStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowStackedBarChartVisitorP) {
        visitor.buildStackedBarChart(element: self)
    }
}

extension CashFlowLine: CashFlowCategoryStackedBarChartVisitableP {
    public func accept(_ visitor: CashFlowCategoryStackedBarChartVisitorP) {
        visitor.buildCategoryStackedBarChart(element: self)
    }
}

extension CashFlowLine: CashFlowIrppVisitableP {
    public func accept(_ visitor: CashFlowIrppVisitorP) {
        visitor.buildIrppChart(element: self)
    }
}

extension CashFlowLine: CashFlowIrppRateVisitableP {
    public func accept(_ visitor: CashFlowIrppRateVisitorP) {
        visitor.buildIrppRateChart(element: self)
    }
}

extension CashFlowLine: CashFlowIsfVisitableP {
    public func accept(_ visitor: CashFlowIsfVisitorP) {
        visitor.buildIsfChart(element: self)
    }
}
