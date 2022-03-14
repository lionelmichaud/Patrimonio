//
//  Simulation.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 26/04/2021.
//

import Foundation
import os
import AVFoundation
import AppFoundation
import Statistics
import Files
import ModelEnvironment
import Persistable
import Persistence
import Succession
import LifeExpense
import PatrimoineModel
import FamilyModel
import SocialAccounts
import SimulationLogger
import Kpi

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Simulation")

public protocol CanResetSimulationP {
    func notifyComputationInputsModification()
}

public final class Simulation: ObservableObject, CanResetSimulationP, PersistableP {
    
    //#if DEBUG
    // URL du fichier de stockage du résultat de calcul au format CSV
    //    static let monteCarloFileUrl = Bundle.main.url(forResource: "Monté-Carlo Kpi.csv", withExtension: nil)
    //#endif
    
    // MARK: - Type Properties
    
    static private let defaultKpiFileName: String = "KPI.json"
    static private var player: AVPlayer { AVPlayer.sharedDingPlayer }
    
    // MARK: - Type Methods
    
    public static func playSound() {
        // jouer le son à la fin de la simulation
        Simulation.player.seek(to: .zero)
        Simulation.player.play()
    }
    
    // MARK: - Properties
    
    // paramètres de la simulation
    @Published public var mode           : SimulationModeEnum = .deterministic
    @Published public var title          = "Simulation"
    @Published public var note           = ""
    @Published public var firstYear      : Int?
    @Published public var lastYear       : Int?
    
    // vecteur d'état de la simulation
    @Published public var currentRunNb   : Int = 0
    private var computationSM        = SimulationComputationStateMachine()
    private var resultsPersistenceSM = SimulationPersistenceStateMachine()
    public  var persistenceSM        = PersistenceStateMachine()
    // résultats de la simulation
    @Published public var socialAccounts        = SocialAccounts()
    @Published public var kpis                  = KpiDictionary()
    @Published public var monteCarloResultTable = SimulationResultTable()
    @Published var currentRunResults    = SimulationResultLine()
    
    // MARK: - Computed Properties
    
    private var computationState : SimulationComputationState {
        computationSM.currentState
    }
    
    private var persistenceState : SimulationPersistenceState {
        resultsPersistenceSM.currentState
    }
    
    public var isComputed      : Bool {
        computationState == .completed
    }
    
    public var resultIsValid   : Bool {
        !(persistenceState == .invalid)
    }
    
    public var resultIsSavable : Bool {
        persistenceState == .savable
    }
    
    public var resultIsSaved   : Bool {
        persistenceState == .saved
    }
    
    public var occuredLegalSuccessions   : [Succession] {
        socialAccounts.legalSuccessions
    }
    public var occuredLifeInsSuccessions : [Succession] {
        socialAccounts.lifeInsSuccessions
    }
    
    // MARK: - Initializers
    
    /// - Note: Utilisé à la création de l'App, avant que le dossier n'ait été sélectionné
    public init() { }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le `bundle`
    /// - Note: Utilisé seulement pour les Tests
    /// - Parameters:
    ///   - bundle: le bundle dans lequel se trouve les fichiers JSON
    /// - Throws: en cas d'échec de lecture des données
    public init(fromBundle bundle : Bundle) {
        kpis = bundle.loadFromJSON(KpiDictionary.self,
                                   from                 : Simulation.defaultKpiFileName,
                                   dateDecodingStrategy : .iso8601,
                                   keyDecodingStrategy  : .useDefaultKeys)
        kpis.setKpisNameFromEnum()
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    /// Initiliser à partir d'un fichier JSON contenu dans le `folder`
    /// - Parameters:
    ///   - folder: le dossier dans lequel se trouve les fichiers JSON
    /// - Throws: en cas d'échec de lecture des données
    public init(fromFolder folder: Folder) throws {
        kpis = try KpiDictionary(fromFile             : Simulation.defaultKpiFileName,
                                 fromFolder           : folder,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        kpis.setKpisNameFromEnum()
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    // MARK: - Methods
    
    /// Lire à partir d'un fichier JSON contenu dans le dossier `folder`
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    /// - Throws: en cas d'échec de lecture des données
    public func loadFromJSON(fromFolder folder: Folder) throws {
        // charger les données JSON
        kpis = try KpiDictionary(fromFile             : Simulation.defaultKpiFileName,
                                 fromFolder           : folder,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)
        kpis.setKpisNameFromEnum()
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    public func saveAsJSON(toFolder folder: Folder) throws {
        try kpis.saveAsJSON(toFile   : Simulation.defaultKpiFileName,
                            toFolder : folder)
        
        // exécuter la transition
        persistenceSM.process(event: .onSave)
    }
    
    /// Traiter un événement
    /// - Parameter event: événement à traiter
    public func process(event: SimulationEvent) {
        computationSM.process(event: event)
        resultsPersistenceSM.process(event: event)
    }
    
    /// Réinitialiser la simulation quand un des paramètres qui influe sur la simulation à changé
    /// Paramètres qui influe sur la simulation:
    ///  Famille,
    ///  Dépenses,
    ///  Patrimoine
    ///  Model
    ///  Définition des KPIs
    public func notifyComputationInputsModification() {
        socialAccounts = SocialAccounts()
        process(event: .onComputationInputsModification)
    }
    
    /// Modifier la définition d'un KPI
    /// - Parameters:
    ///   - key: KPI à modifier
    ///   - value: Nouvelle définition du KPI
    public func setKpi(key   : KpiEnum,
                       value : KPI) {
        kpis[key] = value
        notifyComputationInputsModification()
        persistenceSM.process(event: .onModify)
    }
}

extension Simulation: CustomStringConvertible {
    public var description: String {
        """

        SIMULATION:
          Titre: \(title)
          Note:  \(note)
          Mode:  \(mode)
          Année Début: \(String(describing: firstYear))
          Année Fin  : \(String(describing: lastYear))
          Run en cours: \(String(describing: currentRunNb))
          - Modifié:  \(isModified.frenchString)
          - Terminé:  \(isComputed.frenchString)
          - Sauvable: \(resultIsSavable.frenchString)
        \(String(describing: kpis).withPrefixedSplittedLines("  "))
        \(String(describing: socialAccounts).withPrefixedSplittedLines("  "))
        """
    }
}
