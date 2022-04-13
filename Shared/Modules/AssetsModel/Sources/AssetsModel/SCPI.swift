//
//  SCPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation
import Statistics
import FiscalModel
import EconomyModel
import NamedValue
import Ownership

/// Historique des transactions d'achat ou de vente
public typealias TransactionHistory = [TransactionOrder]

extension TransactionHistory {

    public var earliestBuyingDate : Date {
        self.min(by: { $0.date < $1.date })?.date ?? Date.distantFuture
    }

    public var latestBuyingDate : Date {
        self.max(by: { $0.date < $1.date })?.date ?? Date.distantFuture
    }

    public var averagePrice: Double {
        guard totalQuantity != 0 else {
            return 0
        }
        return totalInvestment / totalQuantity.double()
    }

    public var totalInvestment: Double {
        var total = 0.0
        for transaction in self {
            total += transaction.unitPrice * transaction.quantity.double()
        }
        return total
    }

    public var totalQuantity: Int {
        self.sum(for: \.quantity)
    }
}

extension TransactionHistory: ValidableP {
    public var isValid: Bool {
        self.allSatisfy { $0.isValid }
    }
}

/// Transaction d'achat ou de vente
public struct TransactionOrder: Identifiable, Codable, Equatable, ValidableP {
    enum CodingKeys: CodingKey {
        case quantity
        case unitPrice
        case date
    }

    public var id = UUID()
    public var quantity  : Int    = 0
    public var unitPrice : Double = 0
    public var date      : Date   = Date.now

    public var amount: Double {
        unitPrice * quantity.double()
    }

    public var isValid: Bool {
        unitPrice.isPOZ
    }

    public init(quantity  : Int    = 0,
                unitPrice : Double = 0,
                date      : Date   = Date.now) {
        self.quantity  = quantity
        self.unitPrice = unitPrice
        self.date      = date
    }
}

public typealias ScpiArray = ArrayOfNameableValuable<SCPI>

// MARK: - SCPI à revenus périodiques, annuels et fixes

/// Investissement en parts de SCPI
/// Conformité à JsonCodableToBundleP nécessaire pour les TU; sinon Codable suffit
public struct SCPI: Identifiable, JsonCodableToBundleP, OwnableP, QuotableP, ValidableP {
    
    // MARK: - Nested Types
    
    /// Situation annuelle de l'investissement
    public struct State: Codable, Equatable {
        /// date de la dernière situation connue
        public var date         : Date   = Date.now
        /// Valeur de marché
        public var unitPrice    : Double = 0.0
        /// Rendement annuel servi sur valeur de marché
        public var interestRate : Double = 0.0

        var isValid: Bool {
            unitPrice.isPOZ && interestRate.isPOZ
        }

        public init(date         : Date   = Date.now,
                    unitPrice    : Double = 0.0,
                    interestRate : Double = 0.0) {
            self.date = date
            self.unitPrice = unitPrice
            self.interestRate = interestRate
        }
    }

    enum CodingKeys: CodingKey {
        case name
        case note
        case website
        case ownership
        case transactionHistory
        case lastKnownState
        case revaluatRate
        case willBeSold
        case sellingDate
    }

    // MARK: - Static Properties
    
    public static let prototype = SCPI()

    static var defaultFileName : String = "SCPI.json"
    
    private static var saleCommission    : Double             = 10.0 // %
    private static var simulationMode    : SimulationModeEnum = .deterministic
    // dependencies
    private static var inflationProvider : InflationProviderP!
    private static var fiscalModel       : Fiscal.Model!
    
    // tous ces revenus sont dépréciés de l'inflation
    private static var inflation: Double { // %
        SCPI.inflationProvider!.inflation(withMode: simulationMode)
    }
    
    // MARK: - Static Methods
    
    /// Dependency Injection: Setter Injection
    public static func setInflationProvider(_ inflationProvider : InflationProviderP) {
        SCPI.inflationProvider = inflationProvider
    }
    
    /// Dependency Injection: Setter Injection
    public static func setFiscalModelProvider(_ fiscalModel : Fiscal.Model) {
        SCPI.fiscalModel = fiscalModel
    }
    
    public static func setSimulationMode(to thisMode: SimulationModeEnum) {
        SCPI.simulationMode = thisMode
    }
    
    // MARK: - Properties
    
    public var id = UUID()
    public var name    : String
    public var note    : String = ""
    /// Site web de l'établissement qui détient le bien
    public var website : URL?
    // attention: par défaut la méthode delegate pour ageOf = nil
    // c'est au créateur de l'objet (View ou autre objet du Model) de le faire
    /// Droits de propriété sur le bien
    public var ownership    : Ownership = Ownership()
    /// Niveau de risque sur la valorisation du bien
    public var riskLevel      : RiskLevel? {
        .medium
    }
    /// Niveau de liquidité du bien
    public var liquidityLevel : LiquidityLevel? {
        .medium
    }
    /// Historique des achats
    public var transactionHistory = TransactionHistory()
    /// Date d'achat des premières parts
    public var earliestBuyingDate : Date {
        transactionHistory.earliestBuyingDate
    }
    /// Date d'achat des dernères parts
    public var latestBuyingDate : Date {
        transactionHistory.latestBuyingDate
    }
    /// Prix moyen d'acquisition du bien
    public var averageBuyingPrice  : Double {
        transactionHistory.averagePrice
    }
    /// Dernier situation de marché connue
    public var lastKnownState : State
    /// Agmentation annuelle de la valeur du bien
    public var revaluatRate : Double = 0.0 // %
    /// Le bien sera vendu
    public var willBeSold   : Bool = false
    /// Année de vente du bien (cédé en fin d'année)
    public var sellingDate  : Date = 100.years.fromNow!
    
    // MARK: - Initializer
    
    public init(name               : String             = "",
                note               : String             = "",
                website            : URL?               = nil,
                ownership          : Ownership          = Ownership(),
                transactionHistory : TransactionHistory = TransactionHistory(),
                lastKnownState     : State              = State(),
                revaluatRate       : Double             = 0.0,
                willBeSold         : Bool               = false,
                sellingDate        : Date               = 100.years.fromNow!,
                delegateForAgeOf : ((_ name : String, _ year : Int) -> Int)? = nil) {
        self.name               = name
        self.note               = note
        self.website            = website
        self.ownership          = ownership
        self.transactionHistory = transactionHistory
        self.lastKnownState     = lastKnownState
        self.revaluatRate       = revaluatRate
        self.willBeSold         = willBeSold
        self.sellingDate        = sellingDate
        self.ownership.setDelegateForAgeOf(delegate : delegateForAgeOf)
    }
    
    // MARK: - Methods
    
    /// Valeur de vente du bien estimé à la fin de l'année `year`.
    ///
    /// La valeur du bien est calculée à partir de:
    ///  - la dernière valeur de marché connue, revalorisé annuellement de `revaluatRate` %
    /// depuis la fin de l'année de la date d'évaluation de la valeur de marché.
    ///  - de plus ele est **déflatée** en valeur car sa valeur intrinsèque ne suit pas forcément l'inflation.
    ///
    /// La valeur du bien est décrémentée de la commission d'achat (frais d'acquisition).
    ///
    /// - Note: Les dépenses ne sont pas inflatées. Tout ce qui suit l'inflation (salaires, BNC...) n'est pas inflaté.
    ///         Donc ce qui ne suit pas l'inflation en valeur (actifs financiers...) doit être déflaté de l'inflation en valeur
    ///         car lorsque ces biens seront vendus ils pourront financer moins de dépenses.
    ///
    /// - Parameter year: fin de l'année
    /// - Returns: Valeur actualisé du bien, déflatée de l'inflation, et commission d'achat (frais d'acquisition)  déduite.
    ///
    public func value(atEndOf year: Int) -> Double {
        if isOwned(during: year) {
            return marketValue(atEndOf: year) * (1.0 - SCPI.saleCommission / 100.0)
        } else {
            return 0.0
        }
    }
    public func marketValue(atEndOf year: Int) -> Double {
        marketValuePerShare(atEndOf: year) * transactionHistory.totalQuantity.double()
    }
    public func marketValuePerShare(atEndOf year: Int) -> Double {
        try! futurValue(payement     : 0,
                        interestRate : (revaluatRate - SCPI.inflation) / 100.0,
                        nbPeriod     : poz(year - lastKnownState.date.year),
                        initialValue : lastKnownState.unitPrice)
    }

    /// Revenus annuels net d'inflation (cas taxable à l'IRPP) car calculés en prenant comme base la valeur actuelle de marché **déflatée**.
    ///
    /// Le rendement est appliqué à la valeur de marché et non pas à la valeur de vente.
    /// Le revenu est calculé comme suit: (rendement actuel estimé) x (valeur de marché extrapolée)
    ///
    /// - Parameters:
    ///   - year: durant l'année
    /// - Returns:
    ///   - revenue: revenus inscrit en compte courant avant prélèvements sociaux et IRPP mais net d'inflation
    ///   - taxableIrpp: part des revenus inscrit en compte courant imposable à l'IRPP (après charges sociales)
    ///   - socialTaxes: charges sociales
    ///
    public func yearlyRevenueIRPP(during year: Int)
    -> (revenue    : Double,
        taxableIrpp: Double,
        socialTaxes: Double) {
        let revenue     = (isOwned(during: year) ?
                           marketValue(atEndOf: year - 1) * lastKnownState.interestRate / 100.0 : 0.0)
        let taxableIrpp = SCPI.fiscalModel.financialRevenuTaxes.net(revenue)
        return (revenue    : revenue,
                taxableIrpp: taxableIrpp,
                socialTaxes: revenue - taxableIrpp)
    }
    
    /// Revenus annuels net d'inflation (cas taxable à l'IS)
    ///
    /// Le rendement est appliqué à la valeur de marché et non pas à la valeur de vente.
    /// Le revenu est calculé comme suit: (rendement actuel estimé) x (valeur de marché extrapolée)
    ///
    /// - Parameters:
    ///   - year: durant l'année
    /// - Returns: revenus inscrit en compte courant avant IS mais net d'inflation
    ///
    public func yearlyRevenueIS(during year: Int) -> Double {
        isOwned(during: year) ? marketValue(atEndOf: year - 1) * lastKnownState.interestRate / 100.0 : 0.0
    }
    
    /// True si l'année est postérieure à l'année de vente
    /// - Parameter year: année
    func isSold(before year: Int) -> Bool {
        guard willBeSold else {
            return false
        }
        return year > sellingDate.year
    }
    
    /// True si le bien est en possession au moins un jour pendant l'année demandée
    /// - Parameter year: année
    /// - Note: La première est inclue. L'année de la vente est inclue.
    ///
    func isOwned(during year: Int) -> Bool {
        if isSold(before: year) {
            // le bien est vendu
            return false
        } else if (earliestBuyingDate.year...).contains(year) {
            return true
        } else {
            // le bien n'est pas encore acheté
            return false
        }
    }
    
    /// Produit de la vente l'année de la vente selon le régime de l'IRPP
    /// - Warning: applicable uniquement en régime de l'IRPP
    /// - Parameter year: année
    /// - Returns:
    ///   - `revenue`: produit de la vente net de frais d'agence (commission de vente de 10%)
    ///   - `capitalGain`: plus-value réalisée lors de la vente
    ///   - `socialTaxes`: charges sociales payées sur sur la plus-value
    ///   - `irpp`: impôt sur le revenu dû sur la plus-value
    ///   - `netRevenue`: produit de la vente net de charges sociales `socialTaxes` et d'impôt sur la plus-value `irpp`
    ///
    public func liquidatedValueIRPP (_ year: Int)
    -> (revenue    : Double,
        capitalGain: Double,
        netRevenue : Double,
        socialTaxes: Double,
        irpp       : Double) {
        guard willBeSold && year == sellingDate.year else {
            return (0, 0, 0, 0, 0)
        }
        var detentionDuration    = 0
        var projectedSaleRevenue = 0.0
        var capitalGain          = 0.0
        var socialTaxes          = 0.0
        var irpp                 = 0.0

        for transac in transactionHistory {
            detentionDuration    += sellingDate.year - transac.date.year
            projectedSaleRevenue += marketValuePerShare(atEndOf: sellingDate.year) * transac.quantity.double()
            capitalGain          += projectedSaleRevenue - transac.amount
            socialTaxes          +=
            SCPI.fiscalModel.estateCapitalGainTaxes.socialTaxes(
                capitalGain      : poz(capitalGain),
                detentionDuration: detentionDuration)
            irpp +=
            SCPI.fiscalModel.estateCapitalGainIrpp.irpp(
                capitalGain      : poz(capitalGain),
                detentionDuration: detentionDuration)
        }
        return (revenue     : projectedSaleRevenue,
                capitalGain : capitalGain,
                netRevenue  : projectedSaleRevenue - socialTaxes - irpp,
                socialTaxes : socialTaxes,
                irpp        : irpp)
    }
    
    /// Produit de la vente l'année de la vente selon le régime de l'IS
    /// - Warning: applicable uniquement en régime de l'IS
    /// - Parameter year: année
    /// - Returns:
    ///   - `revenue`: produit de la vente net de frais du gestionnaire (commission de vente de 10%)
    ///   - `capitalGain`: plus-value réalisée lors de la vente
    ///   - `IS`: IS dû sur sur la plus-value
    ///   - `netRevenue`: produit de la vente net d'`IS` sur la plus-value
    ///
    public func liquidatedValueIS (_ year: Int)
    -> (revenue    : Double,
        capitalGain: Double,
        netRevenue : Double,
        IS         : Double) {
        guard willBeSold && year == sellingDate.year else {
            return (0, 0, 0, 0)
        }
        let projectedSaleRevenue = value(atEndOf: sellingDate.year)
        let capitalGain          = projectedSaleRevenue - transactionHistory.totalInvestment
        let IS                   = SCPI.fiscalModel.companyProfitTaxes.IS(poz(capitalGain))
        return (revenue     : projectedSaleRevenue,
                capitalGain : capitalGain,
                netRevenue  : projectedSaleRevenue - IS,
                IS          : IS)
    }
}

// MARK: Extensions
extension SCPI: Comparable {
    public static func < (lhs: SCPI, rhs: SCPI) -> Bool {
        return (lhs.name < rhs.name)
    }
}

extension SCPI {
    /// Vérifie que l'objet est valide
    /// - Warning: Override la méthode par défaut `isValid` du protocole `OwnableP`
    public var isValid: Bool {
        /// vérifier que le nom n'est pas vide
        guard name != "" else {
            return false
        }
        guard ownership.isValid else {
            return false
        }
        guard transactionHistory.isValid else {
            return false
        }
        guard lastKnownState.isValid else {
            return false
        }
        /// vérifier que toutes les dates sont définies
        guard sellingDate >= latestBuyingDate else {
            return false
        }
        return true
    }
}

extension SCPI: CustomStringConvertible {
    public var description: String {
        """
        SCPI: \(name)
        - Note:
        \(note.withPrefixedSplittedLines("    "))
        - Quotation:
          - Risque:    \(riskLevel?.description ?? "indéfini")
          - Liquidité: \(liquidityLevel?.description ?? "indéfini")
        - Droits de propriété:
        \(ownership.description.withPrefixedSplittedLines("  "))
        - Parts achetées entre le \(transactionHistory.earliestBuyingDate.stringShortDate) et le \(transactionHistory.latestBuyingDate.stringShortDate) au prix d'achat moyen de: \(transactionHistory.averagePrice) €
        - Rapporte \(lastKnownState.interestRate) % par an
        - Sa valeur augmente de \(revaluatRate) % par an
        - \(willBeSold ? "Sera vendue le \(sellingDate.stringShortDate) au prix de \(value(atEndOf: sellingDate.year)) €" : "Ne sera pas vendu")
        """
    }
}
