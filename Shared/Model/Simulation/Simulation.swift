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
import EconomyModel
import SocioEconomyModel
import HumanLifeModel
import Files
import ModelEnvironment
import Persistence
import Persistable
import Succession
import LifeExpense
import PersonModel
import PatrimoineModel
import FamilyModel
import SimulationLogger
import OrderedCollections
import Kpi

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.Simulation")

protocol CanResetSimulationP {
    func notifyComputationInputsModification()
}

final class Simulation: ObservableObject, CanResetSimulationP, PersistableP {
   
    //#if DEBUG
    /// URL du fichier de stockage du résultat de calcul au format CSV
    //    static let monteCarloFileUrl = Bundle.main.url(forResource: "Monté-Carlo Kpi.csv", withExtension: nil)
    //#endif

    // MARK: - Type Properties

    static private let defaultKpiFileName: String = "KPI.json"
    static var player: AVPlayer { AVPlayer.sharedDingPlayer }

    // MARK: - Type Methods

    static func playSound() {
        // jouer le son à la fin de la simulation
        Simulation.player.seek(to: .zero)
        Simulation.player.play()
    }

    // MARK: - Properties

    // paramètres de la simulation
    @Published var mode           : SimulationModeEnum = .deterministic
    @Published var title          = "Simulation"
    @Published var note           = ""
    @Published var firstYear      : Int?
    @Published var lastYear       : Int?

    // vecteur d'état de la simulation
    @Published var currentRunNb   : Int = 0
    private var computationSM        = SimulationComputationStateMachine()
    private var resultsPersistenceSM = SimulationPersistenceStateMachine()
    public  var persistenceSM        = PersistenceStateMachine()
    // résultats de la simulation
    @Published var socialAccounts        = SocialAccounts()
    @Published var kpis                  = KpiDictionary()
    @Published var monteCarloResultTable = SimulationResultTable()
    @Published var currentRunResults     = SimulationResultLine()
    
    // MARK: - Computed Properties

    var computationState : SimulationComputationState {
        computationSM.currentState
    }
    var persistenceState : SimulationPersistenceState {
        resultsPersistenceSM.currentState
    }
    var isComputed     : Bool {
        computationState == .completed
    }
    var isSavable      : Bool {
        persistenceState == .savable
    }

    var occuredLegalSuccessions   : [Succession] {
        socialAccounts.legalSuccessions
    }
    var occuredLifeInsSuccessions : [Succession] {
        socialAccounts.lifeInsSuccessions
    }

    // MARK: - Initializers

    /// - Note: Utilisé à la création de l'App, avant que le dossier n'ait été sélectionné
    init() { }

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
        
        // exécuter la transition
        persistenceSM.process(event: .onLoad)
    }
    
    // MARK: - Methods
    
    /// Lire à partir d'un fichier JSON contenu dans le dossier `fromFolder`
    /// - Parameters:
    ///   - folder: dossier où se trouve le fichier JSON à utiliser
    /// - Throws: en cas d'échec de lecture des données
    public func loadFromJSON(fromFolder folder: Folder) throws {
        // charger les données JSON
        kpis = try KpiDictionary(fromFile             : Simulation.defaultKpiFileName,
                                 fromFolder           : folder,
                                 dateDecodingStrategy : .iso8601,
                                 keyDecodingStrategy  : .useDefaultKeys)

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
    func process(event: SimulationEvent) {
        computationSM.process(event: event)
        resultsPersistenceSM.process(event: event)
    }

    /// Réinitialiser la simulation quand un des paramètres qui influe sur la simulation à changé
    /// Paramètres qui influe sur la simulation:
    ///  Famille,
    ///  Dépenses,
    ///  Patrimoine
    func notifyComputationInputsModification() {
        socialAccounts = SocialAccounts()
        process(event: .onComputationInputsModification)
    }
    
    /// Remettre à zéro l'historique des KPI (Histogramme)
    ///  - au début d'un MontéCarlo seulement
    ///  - mais pas à chaque Run
    private func resetKPIs() {
        kpis.reset(withMode: mode)
    }
    
    func setKpi(type  : KpiEnum,
                value : KPI) {
        kpis[type] = value
        notifyComputationInputsModification()
        persistenceSM.process(event: .onModify)
    }
    
    /// Remettre à zéro les historiques des tirages aléatoires avant le lancement d'un MontéCarlo
    private func resetAllRandomHistories(using model: Model) {
        model.humanLife.model!.resetRandomHistory()
        model.economy.model!.resetRandomHistory()
        model.socioEconomy.model!.resetRandomHistory()
    }
    
    private func getCurrentRandomProperties(using model: Model,
                                            _ family                            : Family,
                                            _ dicoOfAdultsRandomProperties      : inout DictionaryOfAdultRandomProperties,
                                            _ dicoOfEconomyRandomVariables      : inout Economy.DictionaryOfRandomVariable,
                                            _ dicoOfSocioEconomyRandomVariables : inout SocioEconomy.DictionaryOfRandomVariable) {
        dicoOfAdultsRandomProperties      = family.currentRandomProperties()
        dicoOfEconomyRandomVariables      = model.economyModel.currentRandomizersValues(withMode: mode)
        dicoOfSocioEconomyRandomVariables = model.socioEconomyModel.currentRandomizersValues(withMode: mode)
    }

    private func getNextRandomProperties(using model                         : Model,
                                         _ family                            : Family,
                                         _ dicoOfAdultsRandomProperties      : inout DictionaryOfAdultRandomProperties,
                                         _ dicoOfEconomyRandomVariables      : inout Economy.DictionaryOfRandomVariable,
                                         _ dicoOfSocioEconomyRandomVariables : inout SocioEconomy.DictionaryOfRandomVariable) {
        // re-générer les propriétés aléatoires de la famille
        dicoOfAdultsRandomProperties = family.nextRun(using: model)

        // re-générer les propriétés aléatoires du modèle macro économique
        dicoOfEconomyRandomVariables = try! model.economyModel.nextRun(simulateVolatility : UserSettings.shared.simulateVolatility,
                                                                       firstYear          : firstYear!,
                                                                       lastYear           : lastYear!)
        // re-générer les propriétés aléatoires du modèle socio économique
        dicoOfSocioEconomyRandomVariables = model.socioEconomyModel.nextRun()
    }

    // swiftlint:disable function_parameter_count
    /// Exécuter une simulation Déterministe ou Aléatoire
    /// - Parameters:
    ///   - model: modèle à utiliser
    ///   - nbOfYears: nombre d'années à construire
    ///   - nbOfRuns: nombre de run à calculer (> 1: mode aléatoire)
    ///   - family: la famille
    ///   - expenses: les dépenses de la famille
    ///   - patrimoine: le patrimoine de la famille
    func compute(using model               : Model,
                 nbOfYears                 : Int,
                 nbOfRuns                  : Int,
                 withFamily family         : Family,
                 withExpenses expenses     : LifeExpensesDic,
                 withPatrimoine patrimoine : Patrimoin) {

        defer {
            // jouer le son à la fin de la simulation
            Simulation.playSound()
        }
        
        let monteCarlo = nbOfRuns > 1
        if monteCarlo && mode != .random {
            customLog.log(level: .fault, "monteCarlo && mode != .random")
            fatalError()
        }
        
        process(event: .onComputationTrigger)
        
        //propriétés indépendantes du nombre de run
        // mettre à jour les variables d'état dans le thread principal
//        DispatchQueue.main.async {
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1
//        } // Dispatcheue.main.async

        var dicoOfAdultsRandomProperties      = DictionaryOfAdultRandomProperties()
        var dicoOfEconomyRandomVariables      = Economy.DictionaryOfRandomVariable()
        var dicoOfSocioEconomyRandomVariables = SocioEconomy.DictionaryOfRandomVariable()

        if monteCarlo {
            // remettre à zéro les historiques des tirages aléatoires
            resetAllRandomHistories(using: model)
            // remettre à zéro la table de résultat
            monteCarloResultTable = SimulationResultTable()
        }

        // sauvegarder l'état initial du patrimoine pour y revenir à la fin de chaque run
        patrimoine.saveState()

        // calculer tous les runs
        for run in 1...nbOfRuns {
//            DispatchQueue.main.async { [self] in
            currentRunNb = run
//            } // DispatchQueue.main.async
            SimulationLogger.shared.log(run      : currentRunNb,
                                        logTopic : LogTopic.simulationEvent,
                                        message  : "Début : \(firstYear!)")
            // récupérer les propriétés aléatoires
            if monteCarlo {
                // re-générer les propriétés aléatoires à chaque run si on est en mode Aléatoire
                getNextRandomProperties(using: model,
                                        family,
                                        &dicoOfAdultsRandomProperties,
                                        &dicoOfEconomyRandomVariables,
                                        &dicoOfSocioEconomyRandomVariables)
            } else {
                // récupérer les propriétés aléatoires courantes en mode Déterministe
                getCurrentRandomProperties(using: model,
                                           family,
                                           &dicoOfAdultsRandomProperties,
                                           &dicoOfEconomyRandomVariables,
                                           &dicoOfSocioEconomyRandomVariables)
            }
            
            // Réinitialiser les comptes sociaux
            socialAccounts = SocialAccounts()
            // Remettre à zéro l'historique des KPI (Histogramme)
            // - au début d'un MontéCarlo seulement
            // - mais pas à chaque Run
            if run == 1 {
                resetKPIs()
                SimulationLogger.shared.reset()
            }
            
            // Exécuter la simulation: construire les comptes sociaux du patrimoine de la famille
            let dicoOfRunKpiResults =
                socialAccounts.build(run            : run,
                                     nbOfYears      : nbOfYears,
                                     withFamily     : family,
                                     withExpenses   : expenses,
                                     withPatrimoine : patrimoine,
                                     withKPIs       : &kpis,
                                     withMode       : mode,
                                     using          : model)
            // Synthèse du Run de Simulation
            currentRunResults =
                SimulationResultLine(runNumber                         : run,
                                     dicoOfAdultsRandomProperties      : dicoOfAdultsRandomProperties,
                                     dicoOfEconomyRandomVariables      : dicoOfEconomyRandomVariables,
                                     dicoOfSocioEconomyRandomVariables : dicoOfSocioEconomyRandomVariables,
                                     dicoOfKpiResults                  : dicoOfRunKpiResults)
            if monteCarlo {
                monteCarloResultTable.append(currentRunResults)
                
                // Dernier run, créer les histogrammes et y ranger
                // les échantillons de KPIs si on est en mode Aléatoire
                if run == nbOfRuns {
                    kpis.generateHistograms()
                }
            }

            patrimoine.restoreState()
        }

        process(event: .onComputationCompletion)
    }
    // swiftlint:enable function_parameter_count

    /// Rejouer un run
    /// - Parameters:
    ///   - thisRun: paramètres du run à rejouer
    func replay(thisRun                   : SimulationResultLine,
                withFamily family         : Family,
                withExpenses expenses     : LifeExpensesDic,
                withPatrimoine patrimoine : Patrimoin,
                using model               : Model) {
        defer {
            // jouer le son à la fin de la simulation
            Simulation.playSound()
        }

        guard let nbOfYears = lastYear - firstYear + 1 else {
            fatalError()
        }
        
        process(event: .onComputationTrigger)

        // propriétés indépendantes du nombre de run
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1

        currentRunNb = 1
        SimulationLogger.shared.reset()
        SimulationLogger.shared.log(run      : currentRunNb,
                                    logTopic : LogTopic.simulationEvent,
                                    message  : "Début : \(firstYear!)")

        // fixer tous les paramètres du run à rejouer
        try! model.economyModel.setRandomValue(to                 : thisRun.dicoOfEconomyRandomVariables,
                                               simulateVolatility : UserSettings.shared.simulateVolatility,
                                               firstYear          : firstYear!,
                                               lastYear           : lastYear!)
        model.socioEconomyModel.setRandomValue(to: thisRun.dicoOfSocioEconomyRandomVariables)
        family.adults.forEach { adult in
            adult.ageOfDeath           = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.ageOfDeath
            adult.nbOfYearOfDependency = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.nbOfYearOfDependency
        }
        
        // Réinitialiser les comptes sociaux
        socialAccounts = SocialAccounts()

        // construire les comptes sociaux du patrimoine de la famille
        _ = socialAccounts.build(run            : currentRunNb,
                                 nbOfYears      : nbOfYears,
                                 withFamily     : family,
                                 withExpenses   : expenses,
                                 withPatrimoine : patrimoine,
                                 withKPIs       : &kpis,
                                 withMode       : mode,
                                 using          : model)
        patrimoine.restoreState()

        process(event: .onComputationCompletion)
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
          - Sauvable: \(isSavable.frenchString)
        \(String(describing: kpis).withPrefixedSplittedLines("  "))
        \(String(describing: socialAccounts).withPrefixedSplittedLines("  "))
        """
    }
}
