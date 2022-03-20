//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 16/01/2022.
//

import Foundation

public struct DiscreteScale {
    
    // MARK: - Properties

    /// Valeurs de seuil de l'échelle
    private let scale        : [Double] // [-inifinity, +inifinity]
    /// Ordre des valeurs de seuils: croissant ou décroissant
    private let scaleOrder   : SortingOrder
    /// Rating le plus faible (pour les valeurs dans [scale[0], scale[1]]
    private let firstRating  : Int
    /// True si l'échelle est valide (au moins une valeur; rangées dans le bon ordre)
    private var isValid      : Bool {
        guard scale.count >= 1 else {
            return false
        }
        switch scaleOrder {
            case .ascending:
                return scale.isSorted {
                    $0 < $1
                }
                
            case .descending:
                return scale.isSorted {
                    $0 > $1
                }
        }
    }
    // MARK: - Initializer
    
    /// Initialize l'échelle
    /// - Parameters:
    ///   - scale: les valeurs doivent être en ordre croissant ou décroissant
    ///   - scaleOrder: ordre souhaité de l'échelle
    ///   - firstRating: rating des valeurs dans le premier intervalle de l'échelle
    public init?(scale       : [Double],
                 scaleOrder  : SortingOrder,
                 firstRating : Int = 0) {
        self.scale       = scale
        self.scaleOrder  = scaleOrder
        self.firstRating = firstRating
        guard isValid else {
            return nil
        }
    }
    
    // MARK: - Methods
    
    /// Retourne la rating (entier) d'une valeur (réelle) selon l'échelle `scale`
    /// - Parameter value: valeur >= à la plus petite valeur de l'échelle ( scale[0] ) dans le cas d'une échelle ascendante
    /// - Returns: le rating entier ou `nil` si value < scale[0] dans le cas d'une échelle ascendante
    public func rating(_ value: Double) -> Int? {
        switch scaleOrder {
            case .ascending:
                return firstRating + scale.lastIndex(where: { $0 <= value })
                
            case .descending:
                return firstRating + scale.lastIndex(where: { $0 >= value })
        }
    }
    
    /// Retourne la rating (énuméré) d'une valeur (réelle) selon l'échelle `scale`
    /// - Parameter value: valeur >= à la plus petite valeur de l'échelle ( scale[0] ) dans le cas d'une échelle ascendante
    /// - Returns: rating énuméré ou `nil` si value < scale[0] dans le cas d'une échelle ascendante
    public func rating<T: RawRepresentable>(_ value: Double) -> T? where T.RawValue == Int {
        switch scaleOrder {
            case .ascending:
                guard let rating = firstRating + scale.lastIndex(where: { $0 <= value }) else {
                    return nil
                }
                return T(rawValue: rating)
                
            case .descending:
                guard let rating = firstRating + scale.lastIndex(where: { $0 >= value }) else {
                    return nil
                }
                return T(rawValue: rating)
        }
    }
}
