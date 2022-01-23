//
//  PensionReversion.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 28/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

public struct PensionReversion: Codable {
    
    // MARK: - Nested types
    
    public struct OldRegimeGeneral: Codable {
        public var minimum: Double // minimum absolu
        public var majoration3enfants: Double // [0, 100] 10%
    }
    
    public struct OldAgircArcco: Codable {
        public var fractionConjoint: Double // [0, 100] 60% des points du conjoint décédé
        public var ageMinimum      : Int // 55 ans
    }
    
    public struct Old: Codable {
        public var general    : OldRegimeGeneral
        public var agircArcco : OldAgircArcco
    }
    
    // https://www.retraite.com/dossier-retraite/pension-de-reversion/evolution-de-la-pension-de-reversion-dans-la-reforme-des-retraites.html
    public struct Model: JsonCodableToBundleP, VersionableP {
        public var version: Version
        var newModelSelected : Bool
        var tauxReversion    : Double // [0, 100] // 70% de la somme des deux pensions
        var oldModel         : Old
    }
    
    // MARK: - Properties
    
    public var model: Model
    
    // MARK: - Computed Properties

    public var newModelSelected: Bool {
        get { model.newModelSelected }
        set { model.newModelSelected = newValue }
    }

    public var newTauxReversion: Double {
        get { model.tauxReversion }
        set { model.tauxReversion = newValue }
    }

    public var oldModel: Old {
        get { model.oldModel }
        set { model.oldModel = newValue }
    }

    // MARK: - Initializer
    
    init(model: Model) {
        self.model = model
    }
    
    // MARK: - Methods
    
    /// Calcule la pension du conjoint survivant + sa pension de réversion
    /// - Parameters:
    ///   - pensionDecedent: pension totale du défunt (régime général + complémentaire)
    ///   - pensionSpouse: pension du conjoint survivant
    ///   - pensionCompDecedent: pension du seul régime complémentaire du défunt
    ///   - spouseAge: age du conjoint survivant
    ///   - bornChildrenNumber: nombre d'enfant né du conjoint survivant
    /// - Returns: pension du conjoint survivant + sa pension de réversion
    public func pensionReversion(pensionDecedent     : Double,
                                 pensionSpouse       : Double,
                                 pensionCompDecedent : Double,
                                 spouseAge           : Int,
                                 bornChildrenNumber  : Int) -> Double {
        if model.newModelSelected {
            return nouvellePensionReversion(pensionDecedent: pensionDecedent,
                                            pensionSpouse  : pensionSpouse)
        } else {
            return anciennePensionReversion(pensionSpouse       : pensionSpouse,
                                            pensionCompDecedent : pensionCompDecedent,
                                            spouseAge           : spouseAge,
                                            bornChildrenNumber  : bornChildrenNumber)
        }
    }
    
    // MARK: - Ancien système
    
    func anciennePensionReversion(pensionSpouse       : Double,
                                  pensionCompDecedent : Double,
                                  spouseAge           : Int,
                                  bornChildrenNumber  : Int) -> Double {
        let pensionReversionGeneral    = anciennePensionReversionGeneral(bornChildrenNumber: bornChildrenNumber)
        let pensionReversionAgircArcco = anciennePensionReversionAgircArcco(pensionCompDecedent: pensionCompDecedent,
                                                                            spouseAge          : spouseAge)
        return pensionSpouse + (pensionReversionGeneral + pensionReversionAgircArcco)
    }
    
    func anciennePensionReversionGeneral(bornChildrenNumber: Int) -> Double {
        switch bornChildrenNumber {
            case 3:
                return model.oldModel.general.minimum * (1.0 + model.oldModel.general.majoration3enfants / 100.0)
            default:
                return model.oldModel.general.minimum
        }
    }
    
    func anciennePensionReversionAgircArcco(pensionCompDecedent : Double,
                                            spouseAge           : Int) -> Double {
        if spouseAge >= model.oldModel.agircArcco.ageMinimum {
            return pensionCompDecedent * model.oldModel.agircArcco.fractionConjoint / 100.0
        } else {
            return 0.0
        }
    }
    
    // MARK: - Nouveau système
    
    func nouvellePensionReversion(pensionDecedent : Double,
                                  pensionSpouse   : Double) -> Double {
        (pensionDecedent + pensionSpouse) * model.tauxReversion / 100.0
    }
    /// Encode l'objet dans un fichier stocké dans le Bundle
    func saveAsJSON(toFile file          : String,
                    toBundle bundle      : Bundle,
                    dateEncodingStrategy : JSONEncoder.DateEncodingStrategy,
                    keyEncodingStrategy  : JSONEncoder.KeyEncodingStrategy) {
        model.saveAsJSON(toFile               : file,
                         toBundle             : bundle,
                         dateEncodingStrategy : dateEncodingStrategy,
                         keyEncodingStrategy  :  keyEncodingStrategy)
    }
}
