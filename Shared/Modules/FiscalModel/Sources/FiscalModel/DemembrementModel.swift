//
//  DemembrementModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - DI: Protocol DemembrementProviderP

public protocol DemembrementProviderP {
    func demembrement(of assetValue   : Double,
                      usufructuaryAge : Int) throws -> (usufructValue : Double,
                                                        bareValue     : Double)
}

// MARK: - Démembrement de propriété

public typealias DemembrementSlice = DemembrementModel.Slice
public typealias DemembrementGrid = [DemembrementModel.Slice]

///  - Note: [Reference](https://www.legifrance.gouv.fr/codes/article_lc/LEGIARTI000006310173/)
public struct DemembrementModel: Codable, DemembrementProviderP {

    // MARK: - Nested types

    enum ModelError: Error {
        case outOfBounds
        case gridSliceIssue
    }
    
    // tranche de barême de l'IRPP
    public struct Slice: Codable, Hashable {
        public var floor    : Int // ans
        public var usuFruit : Double // % [0, 1]
        public var nueProp  : Double {
            1.0 - usuFruit
        }
        public init(floor: Int, usuFruit: Double) {
            self.floor = floor
            self.usuFruit = usuFruit
        }
    }
    
    public struct Model: JsonCodableToBundleP, VersionableP {
        public static var defaultFileName : String = "DemembrementModel.json"
        public var version : Version
        public var grid    : [Slice]
    }
    
    // MARK: - Initializer

    public init(model: DemembrementModel.Model) {
        self.model = model
    }

    // MARK: - Properties

    public var model: Model
    
    // MARK: - Methods

    /// Calcule les valeurs démembrées d'un bien en fonction de l'age de l'usufruitier
    /// - Parameters:
    ///   - assetValue: valeur du bien en pleine propriété
    ///   - usufructuary: age de l'usufruitier
    /// - Returns: valeurs de l'usufruit et de la nue-propriété [0, 1]; [0, 1]
    public func demembrement(of assetValue   : Double,
                             usufructuaryAge : Int) throws
    -> (usufructValue : Double,
        bareValue     : Double) {
        guard usufructuaryAge >= 0 else {
            throw ModelError.outOfBounds
        }
        if usufructuaryAge == 0 {
            return (usufructValue: 1.0, bareValue: 0.0)

        } else if let slice = model.grid.last(where: \.floor, < , usufructuaryAge) {
            return (usufructValue : assetValue * slice.usuFruit,
                    bareValue     : assetValue * slice.nueProp)

        } else {
            throw ModelError.gridSliceIssue
        }
    }
}
