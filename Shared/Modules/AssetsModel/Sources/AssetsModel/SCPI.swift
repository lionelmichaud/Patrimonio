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

public typealias ScpiArray = ArrayOfNameableValuable<SCPI>

// MARK: - SCPI à revenus périodiques, annuels et fixes

// conformité à JsonCodableToBundleP nécessaire pour les TU; sinon Codable suffit
public struct SCPI: Identifiable, JsonCodableToBundleP, OwnableP, QuotableP {
    
    // MARK: - Nested Types
    
    enum CodingKeys: CodingKey {
        case name
        case note
        case website
        case ownership
        case buyingDate
        case buyingPrice
        case willBeSold
        case sellingDate
        case revaluatRate
        case interestRate
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
    /// Date d'achat du bien
    public var buyingDate   : Date
    /// Prix d'achat du bien
    public var buyingPrice  : Double = 0.0
    /// Rendement annuel servi
    public var interestRate : Double = 0.0 // %
    /// Agmentation annuelle de la valeur du bien
    public var revaluatRate : Double = 0.0 // %
    /// Le bien sera vendu
    public var willBeSold   : Bool = false
    /// Année de vente du bien (cédé en fin d'année)
    public var sellingDate  : Date = 100.years.fromNow!
    
    // MARK: - Initializer
    
    public init(name         : String    = "",
                note         : String    = "",
                ownership    : Ownership = Ownership(),
                buyingDate   : Date      = CalendarCst.now,
                buyingPrice  : Double    = 0.0,
                interestRate : Double    = 0.0,
                revaluatRate : Double    = 0.0,
                willBeSold   : Bool      = false,
                sellingDate  : Date      = 100.years.fromNow!,
                delegateForAgeOf : ((_ name : String, _ year : Int) -> Int)? = nil) {
        self.name         = name
        self.note         = note
        self.ownership    = ownership
        self.buyingDate   = buyingDate
        self.buyingPrice  = buyingPrice
        self.interestRate = interestRate
        self.revaluatRate = revaluatRate
        self.willBeSold   = willBeSold
        self.sellingDate  = sellingDate
        self.ownership.setDelegateForAgeOf(delegate: delegateForAgeOf)
    }
    
    // MARK: - Methods
    
    /// Valeur du bien à la fin de l'année `year`.
    ///
    /// Le bien est revalorisé annuellement de `revaluatRate` % depuis sa date d'acquisition mais il n'est pas déflaté en valeur.
    ///
    /// La valeur du bien est décrémentée de la commission d'achat (frais d'acquisition).
    ///
    /// Ce sont ses revenus qui sont déflatés de l'inflation.
    ///
    /// - Parameter year: fin de l'année
    /// - Returns: Valeur actualisé du bien, non déflatée de l'inflation, mais commission d'achat (frais d'acquisition)  déduite.
    public func value(atEndOf year: Int) -> Double {
        if isOwned(during: year) {
            return try! futurValue(payement     : 0,
                                   interestRate : revaluatRate / 100.0,
                                   nbPeriod     : year - buyingDate.year,
                                   initialValue : buyingPrice) * (1.0 - SCPI.saleCommission / 100.0)
        } else {
            return 0.0
        }
    }
    
    /// Revenus annuels net d'inflation (cas taxable à l'IRPP)
    ///
    /// On retire l'inflation du taux de rendement annuel car côté dépenses, celles-ci ne sont pas augmentée de l'inflation chaque année.
    ///
    /// Le revenu est calculé comme suit: (rendement - inflation) x valeur d'acquisition
    ///
    /// - Parameters:
    ///   - year: durant l'année
    /// - Returns:
    ///   - revenue: revenus inscrit en compte courant avant prélèvements sociaux et IRPP mais net d'inflation
    ///   - taxableIrpp: part des revenus inscrit en compte courant imposable à l'IRPP (après charges sociales)
    ///   - socialTaxes: charges sociales
    public func yearlyRevenueIRPP(during year: Int)
    -> (revenue    : Double,
        taxableIrpp: Double,
        socialTaxes: Double) {
        let revenue     = (isOwned(during: year) ?
                            buyingPrice * (interestRate - SCPI.inflation) / 100.0 :
                            0.0)
        let taxableIrpp = SCPI.fiscalModel.financialRevenuTaxes.net(revenue)
        return (revenue    : revenue,
                taxableIrpp: taxableIrpp,
                socialTaxes: revenue - taxableIrpp)
    }
    
    /// Revenus annuels net d'inflation (cas taxable à l'IS)
    ///
    /// On retire l'inflation du taux de rendement annuel car côté dépenses, celles-ci ne sont pas augmentée de l'inflation chaque année.
    ///
    /// Le revenu est calculé comme suit: (rendement - inflation) x valeur d'acquisition
    ///
    /// - Parameters:
    ///   - year: durant l'année
    /// - Returns: revenus inscrit en compte courant avant IS mais net d'inflation
    public func yearlyRevenueIS(during year: Int) -> Double {
        isOwned(during: year) ?
                            buyingPrice * (interestRate - SCPI.inflation) / 100.0 :
                            0.0
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
    func isOwned(during year: Int) -> Bool {
        if isSold(before: year) {
            // le bien est vendu
            return false
        } else if (buyingDate.year...).contains(year) {
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
    public func liquidatedValueIRPP (_ year: Int)
    -> (revenue    : Double,
        capitalGain: Double,
        netRevenue : Double,
        socialTaxes: Double,
        irpp       : Double) {
        guard willBeSold && year == sellingDate.year else {
            return (0, 0, 0, 0, 0)
        }
        let detentionDuration    = sellingDate.year - buyingDate.year
        let projectedSaleRevenue = value(atEndOf: sellingDate.year)
        let capitalGain          = projectedSaleRevenue - buyingPrice
        let socialTaxes          =
            SCPI.fiscalModel.estateCapitalGainTaxes.socialTaxes(
                capitalGain      : zeroOrPositive(capitalGain),
                detentionDuration: detentionDuration)
        let irpp              =
            SCPI.fiscalModel.estateCapitalGainIrpp.irpp(
                capitalGain      : zeroOrPositive(capitalGain),
                detentionDuration: detentionDuration)
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
    ///   - `revenue`: produit de la vente net de frais d'agence (commission de vente de 10%)
    ///   - `capitalGain`: plus-value réalisée lors de la vente
    ///   - `IS`: IS dû sur sur la plus-value
    ///   - `netRevenue`: produit de la vente net d'`IS` sur la plus-value
    public func liquidatedValueIS (_ year: Int)
    -> (revenue    : Double,
        capitalGain: Double,
        netRevenue : Double,
        IS         : Double) {
        guard willBeSold && year == sellingDate.year else {
            return (0, 0, 0, 0)
        }
        let projectedSaleRevenue = value(atEndOf: sellingDate.year)
        let capitalGain          = projectedSaleRevenue - buyingPrice
        let IS                   = SCPI.fiscalModel.companyProfitTaxes.IS(zeroOrPositive(capitalGain))
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
        - Acheté le \(buyingDate.stringShortDate) au prix d'achat de: \(buyingPrice) €
        - Rapporte \(interestRate - SCPI.inflation) % par an net d'inflation
        - Sa valeur augmente de \(revaluatRate) % par an
        - \(willBeSold ? "Sera vendue le \(sellingDate.stringShortDate) au prix de \(value(atEndOf: sellingDate.year)) €" : "Ne sera pas vendu")
        """
    }
}
