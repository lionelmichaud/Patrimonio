//
//  HumanLifeModel.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 07/10/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import Persistable
import AppFoundation
import Statistics
import Files
import FileAndFolder

// MARK: - SINGLETON: Human Life Model

public struct HumanLife: PersistableP {
 
    public static var defaultFileName : String = "HumanLifeModelConfig.json"

    // MARK: - Nested Types
    
    public enum RandomVariable: String, PickableEnum {
        case menLifeExpectation    = "Espérance de Vie d'un Homme"
        case womenLifeExpectation  = "Espérance de Vie d'uns Femme"
        case nbOfYearsOfdependency = "Nombre d'années de Dépendance"
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public struct Model: JsonCodableToFolderP, JsonCodableToBundleP {
        public var menLifeExpectation    : ModelRandomizer<DiscreteRandomGenerator>
        public var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
        public var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
        public let minAgeUniversity      : Int
        public let minAgeIndependance    : Int

        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        func initialized() -> Model {
            var model = self
            model.menLifeExpectation.rndGenerator.initialize()
            model.womenLifeExpectation.rndGenerator.initialize()
            model.nbOfYearsOfdependency.rndGenerator.initialize()
            return model
        }
        
        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
        public mutating func resetRandomHistory() {
            menLifeExpectation.resetRandomHistory()
            womenLifeExpectation.resetRandomHistory()
            nbOfYearsOfdependency.resetRandomHistory()
        }
        
        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
        /// - Returns: dictionnaire donnant pour chaque variable aléatoire son historique de tirage
        func randomHistories() -> [RandomVariable: [Double]?] {
            var dico = [RandomVariable: [Double]?]()
            for randomVariable in RandomVariable.allCases {
                switch randomVariable {
                    case .menLifeExpectation:
                        dico[randomVariable] = menLifeExpectation.randomHistory
                    case .womenLifeExpectation:
                        dico[randomVariable] = womenLifeExpectation.randomHistory
                    case .nbOfYearsOfdependency:
                        dico[randomVariable] = nbOfYearsOfdependency.randomHistory
                }
            }
            return dico
        }    
    }
    
    // MARK: - Static Properties
    
    public var model : Model
    public var persistenceSM = PersistenceStateMachine()

    // MARK: - Initializer
    
    public init(fromFolder folder: Folder) throws {
        self.model = try Model(fromFile    : HumanLife.defaultFileName,
                               fromFolder           : folder,
                               dateDecodingStrategy : .iso8601,
                               keyDecodingStrategy  : .useDefaultKeys).initialized()

        // exécuter la transition
        persistenceSM.process(event: .load)
    }

    public init(for aClass: AnyClass) {
        let classBundle = Bundle(for: aClass)
        self.model = classBundle.loadFromJSON(Model.self,
                                              from                 : HumanLife.defaultFileName,
                                              dateDecodingStrategy : .iso8601,
                                              keyDecodingStrategy  : .useDefaultKeys)

        // exécuter la transition
        persistenceSM.process(event: .load)
    }

    // MARK: - Methods

    public func saveAsJSON(toFolder folder: Folder) throws {
        // encode to JSON file
        try model.saveAsJSON(toFile               : HumanLife.defaultFileName,
                             toFolder             : folder,
                             dateEncodingStrategy : .iso8601,
                             keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }

    func saveAsJSONToBundleOf(aClass: AnyClass) {
        let bundle = Bundle(for: aClass)
        // encode to JSON file
        bundle.saveAsJSON(model,
                          to                   : HumanLife.defaultFileName,
                          dateEncodingStrategy : .iso8601,
                          keyEncodingStrategy  : .useDefaultKeys)
        // exécuter la transition
        persistenceSM.process(event: .save)
    }
}
