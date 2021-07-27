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
import FileAndFolder

// MARK: - Human Life Model

public struct HumanLife: PersistableModel {
    
    // MARK: - Nested Types
    
    public enum RandomVariable: String, PickableEnum {
        case menLifeExpectation    = "Espérance de Vie d'un Homme"
        case womenLifeExpectation  = "Espérance de Vie d'uns Femme"
        case nbOfYearsOfdependency = "Nombre d'années de Dépendance"
        
        public var pickerString: String {
            return self.rawValue
        }
    }
    
    public struct Model: JsonCodableToFolderP, JsonCodableToBundleP, Initializable {
        public var menLifeExpectation    : ModelRandomizer<DiscreteRandomGenerator>
        public var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
        public var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
        public let minAgeUniversity      : Int
        public let minAgeIndependance    : Int
        
        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
        public func initialized() -> Model {
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
    
    public static var defaultFileName: String = "HumanLifeModelConfig.json"
    
    // MARK: - Properties
    
    public var model         : Model?
    public var persistenceSM : PersistenceStateMachine
    
    public var menLifeExpectationDeterministic: Int {
        get {
            Int(model!.menLifeExpectation.defaultValue.rounded())
        }
        set {
            model?.menLifeExpectation.defaultValue = newValue.double()
            // mémoriser la modification
            persistenceSM.process(event: .modify)
        }
    }
    public var womenLifeExpectationDeterministic: Int {
        get {
            Int(model!.womenLifeExpectation.defaultValue.rounded())
        }
        set {
            model?.womenLifeExpectation.defaultValue = newValue.double()
            // mémoriser la modification
            persistenceSM.process(event: .modify)
        }
    }
    public var nbOfYearsOfdependencyDeterministic: Int {
        get {
            Int(model!.nbOfYearsOfdependency.defaultValue.rounded())
        }
        set {
            model?.nbOfYearsOfdependency.defaultValue = newValue.double()
            // mémoriser la modification
            persistenceSM.process(event: .modify)
        }
    }

    // MARK: - Initializers

    public init() {
        self.persistenceSM = PersistenceStateMachine()
    }
}

//public struct HumanLife: PersistableP {
//
//    public static var defaultFileName : String = "HumanLifeModelConfig.json"
//
//    // MARK: - Nested Types
//
//    public enum RandomVariable: String, PickableEnum {
//        case menLifeExpectation    = "Espérance de Vie d'un Homme"
//        case womenLifeExpectation  = "Espérance de Vie d'uns Femme"
//        case nbOfYearsOfdependency = "Nombre d'années de Dépendance"
//
//        public var pickerString: String {
//            return self.rawValue
//        }
//    }
//
//    public struct Model: JsonCodableToFolderP, JsonCodableToBundleP, Initializable {
//        public var menLifeExpectation    : ModelRandomizer<DiscreteRandomGenerator>
//        public var womenLifeExpectation  : ModelRandomizer<DiscreteRandomGenerator>
//        public var nbOfYearsOfdependency : ModelRandomizer<DiscreteRandomGenerator>
//        public let minAgeUniversity      : Int
//        public let minAgeIndependance    : Int
//
//        /// Initialise le modèle après l'avoir chargé à partir d'un fichier JSON du Bundle Main
//        public func initialized() -> Model {
//            var model = self
//            model.menLifeExpectation.rndGenerator.initialize()
//            model.womenLifeExpectation.rndGenerator.initialize()
//            model.nbOfYearsOfdependency.rndGenerator.initialize()
//            return model
//        }
//
//        /// Vide l'ihistorique des tirages de chaque variable aléatoire du modèle
//        public mutating func resetRandomHistory() {
//            menLifeExpectation.resetRandomHistory()
//            womenLifeExpectation.resetRandomHistory()
//            nbOfYearsOfdependency.resetRandomHistory()
//        }
//
//        /// Retourne un dictionnaire donnant pour chaque variable aléatoire son historique de tirage
//        /// Retourne la suite de valeurs aléatoires tirées pour chaque Run d'un Monté-Carlo
//        /// - Returns: dictionnaire donnant pour chaque variable aléatoire son historique de tirage
//        func randomHistories() -> [RandomVariable: [Double]?] {
//            var dico = [RandomVariable: [Double]?]()
//            for randomVariable in RandomVariable.allCases {
//                switch randomVariable {
//                    case .menLifeExpectation:
//                        dico[randomVariable] = menLifeExpectation.randomHistory
//                    case .womenLifeExpectation:
//                        dico[randomVariable] = womenLifeExpectation.randomHistory
//                    case .nbOfYearsOfdependency:
//                        dico[randomVariable] = nbOfYearsOfdependency.randomHistory
//                }
//            }
//            return dico
//        }
//    }
//
//    // MARK: - Static Properties
//
//    public var model : Model
//    public var persistenceSM = PersistenceStateMachine()
//
//    // MARK: - Initializer
//
//    /// Charger le modèle à partir d'un fichier JSON contenu dans le fichier `defaultFileName`
//    /// du dossier `folder` et l'initialiser
//    /// - Parameters:
//    ///   - folder: le dossier dans lequel chercher le fichier nommé `defaultFileName`
//    public init(fromFolder folder: Folder) throws {
//        self.model =
//            try Model(fromFile             : HumanLife.defaultFileName,
//                      fromFolder           : folder,
//                      dateDecodingStrategy : .iso8601,
//                      keyDecodingStrategy  : .useDefaultKeys)
//            .initialized()
//        // exécuter la transition
//        persistenceSM.process(event: .load)
//    }
//
//    /// Charger le modèle à partir d'un fichier JSON contenu dans le fichier `defaultFileName`
//    /// du `bundle` et l'initialiser
//    /// - Parameters:
//    ///   - bundle: le bundle dans lequel chercher le fichier nommé `defaultFileName`
//    public init(fromBundle bundle: Bundle) {
//        self.model =
//            bundle.loadFromJSON(Model.self,
//                                from                 : HumanLife.defaultFileName,
//                                dateDecodingStrategy : .iso8601,
//                                keyDecodingStrategy  : .useDefaultKeys)
//            .initialized()
//        // exécuter la transition
//        persistenceSM.process(event: .load)
//    }
//
//    // MARK: - Methods
//
//    /// Enregistrer le modèle au format JSON dans un fichier nommé `defaultFileName`
//    /// dans le folder nommé `folder` du répertoire `Documents`
//    /// - Parameters:
//    ///   - folder: folder du répertoire `Documents`
//    public func saveAsJSON(toFolder folder: Folder) throws {
//        // encode to JSON file
//        try model.saveAsJSON(toFile               : HumanLife.defaultFileName,
//                             toFolder             : folder,
//                             dateEncodingStrategy : .iso8601,
//                             keyEncodingStrategy  : .useDefaultKeys)
//        // exécuter la transition
//        persistenceSM.process(event: .save)
//    }
//
//    /// Enregistrer le modèle au format JSON dans un fichier nommé `defaultFileName`
//    /// du `bundle` et l'initialiser
//    /// - Parameters:
//    ///   - bundle: le bundle dans lequel stocker le fichier nommé `defaultFileName`
//    public func saveAsJSON(toBundle bundle: Bundle) {
//        bundle.saveAsJSON(model,
//                          to                   : HumanLife.defaultFileName,
//                          dateEncodingStrategy : .iso8601,
//                          keyEncodingStrategy  : .useDefaultKeys)
//        // exécuter la transition
//        persistenceSM.process(event: .save)
//    }
//}
