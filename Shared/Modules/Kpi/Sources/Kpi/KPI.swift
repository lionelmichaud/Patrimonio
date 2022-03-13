//
//  KPI.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Statistics
import FileAndFolder
import OrderedCollections

// MARK: - KpiDictionary : tableau de KPI

public typealias KpiDictionary = OrderedDictionary<KpiEnum, KPI>

extension KpiDictionary: JsonCodableToFolderP {}

public extension KpiDictionary {
    
    mutating func setKpisNameFromEnum() {
        for key in KpiEnum.allCases {
            var kpi = self[key]
            kpi?.name = key.rawValue
            self[key] = kpi
        }
    }
    
    /// Remettre à zéro l'historique des KPI (Histogramme)
    mutating func reset(withMode mode : SimulationModeEnum) {
        self = mapValues { kpi in
            var newKPI = kpi
            newKPI.reset(withMode: mode)
            return newKPI
        }
    }

    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    ///
    /// - Warning: Les échantillons doivent avoir été enregistrées au préalable
    ///
    mutating func generateHistograms() {
        self = mapValues { kpi in
            var newKPI = kpi
            newKPI.sortHistogram()
            return newKPI
        }
    }

    /// Est-ce que tous les objectifs sont atteints ?
    /// - Warning:
    ///     - Retourne nil si au moins une des valeurs n'est pas définie
    ///     - Ne doit être appelées qu'après la fin du dernier Run
    ///
    func allObjectivesAreReached(withMode mode : SimulationModeEnum) -> Bool? {
        var result = true
        for (_, kpi) in self {
            if let objectiveIsReached = kpi.objectiveIsReached(withMode: mode) {
                result = result && objectiveIsReached
            } else {
                // un résultat est inconnu
                return nil
            }
        }
        // tous les résultats sont connus
        return result
    }
}

// MARK: - KPI : indicateur de performance

/// KPI
///
/// Usage:
/// ```
///       // le KPI doit être >= 100_000.0 avec une probabilité de 95%
///       var kpi = KPI(name                    : "My KPI",
///                      note                    : "KPI description",
///                      objective               : 100_000.0,
///                      withProbability         : 0.95,
///                      comparatorWithObjective : .maximize)
///
///       // ajoute un(des) échantillon(s) à l'histogramme
///       kpi.record(kpiSample1, withMode: .random)
///       kpi.record(kpiSample2, withMode: .random)
///       kpi.record(kpiSample3, withMode: .random)
///
///       // l'objectif est-il atteint ?
///       let objectiveReached = kpi.objectiveIsReachedWithLastValue(withMode: .random)
///       let objectiveReached = kpi.objectiveIsReached(withMode: .random)
///
///       // récupère la valeur déterministe du KPI
///       // ou valeur statistique du KPI dépassée avec la proba objectif (withProbability)
///       let kpiValue = kpi.value()
///
///       // valeur statistique du KPI dépassée avec un proba ≥ 90%
///       let kpiValue = kpi.value(for: 0.90)
///
///       // remet à zéro l'historique du KPI
///       kpi.reset()
/// ```
///
public struct KPI: Identifiable {

    // MARK: - Netsed Types

    public enum ComparatorEnum: String, Codable {
        case maximize = "plus grand que"
        case minimize = "plus petit que"
    }

    // MARK: - Static Properties
    
    static let nbBucketsInHistograms = 100
    
    // MARK: - Properties
    
    public var id = UUID()
    public var name : String = ""
    public var note : String
    // objectif à atteindre
    public var objective      : Double
    // probability d'atteindre l'objectif
    public var probaObjective : Double
    // valeur déterministe
    private var valueKPI: Double?
    // histogramme des valeurs du KPI
    public var histogram: Histogram = Histogram(name: "")
    // comparateur / seuil
    public var comparator: ComparatorEnum = .maximize
    private var isBetterThanObjective: ((Double, Double) -> Bool) = (>=)

    // MARK: - Initializers
    
    public init(name                    : String,
                note                    : String = "",
                objective               : Double,
                withProbability         : Double,
                comparatorWithObjective : ComparatorEnum = .maximize) {
        self.name           = name
        self.note           = note
        self.objective      = objective
        self.probaObjective = withProbability
        // initializer l'histogramme sans les cases
        self.histogram      = Histogram(name: name)
        switch comparatorWithObjective {
            case .maximize:
                isBetterThanObjective = (>=)
            case .minimize:
                isBetterThanObjective = (<=)
        }
    }
    
    // MARK: - Methods
    
    public mutating func record(_ value       : Double,
                                withMode mode : SimulationModeEnum) {
        switch mode {
            case .deterministic:
                self.valueKPI = value
                
            case .random:
                histogram.record(value)
        }
    }
    
    /// remettre à zéero l'historique du KPI (Histogramme)
    public mutating func reset(withMode mode: SimulationModeEnum) {
        switch mode {
            case .deterministic:
                self.valueKPI = nil
                
            case .random:
                histogram.reset()
        }
    }
    
    /// Initialise les cases de l'histogramme et range les échantillons dans les cases
    ///
    /// - Warning: les échantillons doivent avoir été enregistrées au préalable
    ///
    mutating func sortHistogram() {
        histogram.sort(distributionType : .continuous,
                       openEnds         : false,
                       bucketNb         : KPI.nbBucketsInHistograms)
    }
    
    /// Retourne true si la valeur du KPI a été définie au cours de la simulation (.deterministic)
    /// ou peut être calculée (.random)
    public func hasValue(for mode: SimulationModeEnum) -> Bool {
        value(withMode: mode) != nil
    }
    
    /// Valeur du KPI
    ///
    /// - Note:
    ///     Mode Déterministe:
    ///     - retourne la valeur unique du KPI
    ///
    ///     Mode Aléatoire:
    ///     - retourne la valeur X de l'indicateur telle que :
    ///       - la probabilité P(x > X) est = à la probabilité Pobjectif (cas .maximize).
    ///       - la probabilité P(x < X) est = à la probabilité Pobjectif (cas .minimize).
    ///
    ///     P(x > X) = 1 - P((x ≤ X)
    ///
    public func value(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                switch comparator {
                    case .maximize:
                        return percentile(for: 1.0 - probaObjective)
                    case .minimize:
                        return percentile(for: probaObjective)
                }
        }
    }
    
    public func lastValue(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.lastRecordedValue
        }
    }
    
    /// Valeur du KPI avec la probabilité objectif
    ///
    /// Renvoie la valeur x telle que P(X<x) >= probability
    /// - Parameter probability: probabilité
    /// - Returns: x telle que P(X<x) >= probability
    /// - Warning: probability in [0, 1]
    public func percentile(for probability: Double) -> Double? {
        histogram.percentile(for: probability)
    }
    
    /// Renvoie la probabilité P(sample ≥ x)
    /// - Parameter x: valeure dont il faut rechercher la probabilité
    /// - Returns: probabilité P(sample ≥ x)
    public func probability(for value: Double) -> Double? {
        histogram.probability(for: value)
    }

    /// Valeur moyenne du KPI
    public func average(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.average
        }
    }
    
    /// Valeur médianne du KPI
    public func median(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.median
        }
    }
    
    /// Valeur min du KPI
    public func min(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.min
        }
    }
    
    /// Valeur max du KPI
    public func max(withMode mode: SimulationModeEnum) -> Double? {
        switch mode {
            case .deterministic:
                return valueKPI
                
            case .random:
                return histogram.max
        }
    }
    
    public func objectiveIsReached(for value: Double) -> Bool {
        isBetterThanObjective(value, objective)
    }
    
    /// Retourrne true si l'objectif de valeur est atteint lors du run unique (.deterministic)
    /// ou statistiquement (avec une probabilité minimale) sur l'ensemble des runs (.random)
    public func objectiveIsReached(withMode mode: SimulationModeEnum) -> Bool? {
        guard let value = self.value(withMode: mode) else {
            return nil
        }
        // est-ce que la probabilité obtenue est conforme à l'objectif ?
        return objectiveIsReached(for: value)
    }
    
    /// Retourrne true si l'objectif de valeur est atteint lors du run unique (.deterministic)
    /// ou sur le dernier run (.random)
    public func objectiveIsReachedWithLastValue(withMode mode: SimulationModeEnum) -> Bool? {
        guard let lastValue = self.lastValue(withMode: mode) else {
            return nil
        }
        return isBetterThanObjective(lastValue, objective)
    }
}

extension KPI: Codable {
    enum CodingKeys: String, CodingKey {
        case note           = "note"
        case objective      = "valeur objectif"
        case probaObjective = "probabilité minimum d'atteindre l'objectif"
        case comparator     = "comparateur avec l'objectif"
    }
}

extension KPI: CustomStringConvertible {
    public var description: String {
        """

        KPI:
          nom:  \(name)
          note: \(note)
          valeur objectif: \(objective.rounded())
          probabilité minimum d'atteindre l'objectif: \(probaObjective.percentString(digit: 2))
          comparateur avec l'objectif: \(comparator)

        """
    }
}
