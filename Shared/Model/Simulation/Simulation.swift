//
//  Simulation.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 26/04/2021.
//

import Foundation
import AVFoundation
import AppFoundation
import Statistics
import EconomyModel
import SocioEconomyModel
import HumanLifeModel

protocol CanResetSimulation {
    func reset()
}

class Simulation: ObservableObject, CanResetSimulation {

    //#if DEBUG
    /// URL du fichier de stockage du résultat de calcul au format CSV
    //    static let monteCarloFileUrl = Bundle.main.url(forResource: "Monté-Carlo Kpi.csv", withExtension: nil)
    //#endif

    static var player: AVPlayer { AVPlayer.sharedDingPlayer }

    // MARK: - Properties

    // paramètres de la simulation
    @Published var mode           : SimulationModeEnum = .deterministic
    @Published var title          = "Simulation"
    @Published var firstYear      : Int?
    @Published var lastYear       : Int?

    // vecteur d'état de la simulation
    @Published var currentRunNb   : Int = 0
    @Published var isComputed     = false
    @Published var isSaved        = false
    //    @Published var isComputing    = false

    // résultats de la simulation
    @Published var socialAccounts = SocialAccounts()
    @Published var kpis           = KpiArray()
    @Published var resultTable    = SimulationResultTable()

    // MARK: - Computed Properties

    var occuredLegalSuccessions: [Succession] {
        socialAccounts.legalSuccessions
    }
    var occuredLifeInsSuccessions: [Succession] {
        socialAccounts.lifeInsSuccessions
    }

    // MARK: - Initializers

    init() {
        /// initialiser les KPI
        let kpiMinimumCash = KPI(name            : SimulationKPIEnum.minimumAsset.displayString,
                                 note            : SimulationKPIEnum.minimumAsset.note,
                                 objective       : 200_000.0,
                                 withProbability : 0.98)
        kpis.append(kpiMinimumCash)

        let kpiAssetsAtFirstDeath = KPI(name            : SimulationKPIEnum.assetAt1stDeath.displayString,
                                        note            : SimulationKPIEnum.assetAt1stDeath.note,
                                        objective       : 200_000.0,
                                        withProbability : 0.98)
        kpis.append(kpiAssetsAtFirstDeath)

        let kpiAssetsAtLastDeath = KPI(name            : SimulationKPIEnum.assetAt2ndtDeath.displayString,
                                       note            : SimulationKPIEnum.assetAt2ndtDeath.note,
                                       objective       : 200_000.0,
                                       withProbability : 0.98)
        kpis.append(kpiAssetsAtLastDeath)
    }

    // MARK: - Methods

    /// Réinitialiser la simulation quand un des paramètres qui influe sur la simulation à changé
    /// Paramètres qui influe sur la simulation:
    ///  Famille,
    ///  Dépenses,
    ///  Patrimoine
    ///
    /// - Note:
    ///   - les comptes sociaux sont réinitialisés
    ///   - les années de début et fin sont réinitialisées à nil
    ///   - les successions sont réinitilisées
    ///   - les KPI peuvent être réinitialisés
    ///
    /// - Parameters:
    ///   - patrimoine: le patrimoine
    ///   - includingKPIs: réinitialiser les KPI (seulement sur le premier run)
    ///
    func reset() {
        // réinitialiser les comptes sociaux du patrimoine de la famille
        socialAccounts = SocialAccounts()
        isComputed     = false
        isSaved        = false
    }

    /// remettre à zéro l'historique des KPI (Histogramme)
    /// - au début d'un MontéCarlo seulement
    /// - mais pas à chaque Run
    private func reset(includingKPIs: Bool = true) {
        // réinitialiser les comptes sociaux du patrimoine de la famille
        reset()

        // remettre à zéro l'historique des KPI (Histogramme)
        //  - au début d'un MontéCarlo seulement
        //  - mais pas à chaque Run
        if includingKPIs {
            KpiArray.reset(theseKPIs: &kpis, withMode: mode)
        }
    }

    /// remettre à zéro les historiques des tirages aléatoires avant le lancement d'un MontéCarlo
    private func resetAllRandomHistories() {
        HumanLife.model.resetRandomHistory()
        Economy.model.resetRandomHistory()
        SocioEconomy.model.resetRandomHistory()
    }

    private func nextRandomProperties(_ family                            : Family,
                                      _ dicoOfEconomyRandomVariables      : inout Economy.DictionaryOfRandomVariable,
                                      _ dicoOfSocioEconomyRandomVariables : inout SocioEconomy.DictionaryOfRandomVariable) {
        // re-générer les propriétés aléatoires de la famille
        family.nextRandomProperties()
        // re-générer les propriétés aléatoires du modèle macro économique
        dicoOfEconomyRandomVariables = try! Economy.model.nextRun(withMode           : mode,
                                                                  simulateVolatility : UserSettings.shared.simulateVolatility,
                                                                  firstYear          : firstYear!,
                                                                  lastYear           : lastYear!)
        // re-générer les propriétés aléatoires du modèle socio économique
        dicoOfSocioEconomyRandomVariables = SocioEconomy.model.next()
    }

    private func closeMonteCarloRun(_ family                            : Family, // swiftlint:disable:this function_parameter_count
                                    _ run                               : Int,
                                    _ dicoOfEconomyRandomVariables      : Economy.DictionaryOfRandomVariable,
                                    _ dicoOfSocioEconomyRandomVariables : SocioEconomy.DictionaryOfRandomVariable,
                                    _ dicoOfKpiResults                  : DictionaryOfKpiResults,
                                    _ nbOfRuns                          : Int) {
        // récupérer les propriétés aléatoires des adultes de la famille
        var dicoOfAdultsRandomProperties = DictionaryOfAdultRandomProperties()
        family.members.forEach { person in
            if let adult = person as? Adult {
                dicoOfAdultsRandomProperties[adult.displayName] = AdultRandomProperties(ageOfDeath          : adult.ageOfDeath,
                                                                                        nbOfYearOfDependency: adult.nbOfYearOfDependency)
            }
        }
        // Synthèse du Run de Simulation
        let currentRunResults = SimulationResultLine(runNumber                         : run,
                                                     dicoOfAdultsRandomProperties      : dicoOfAdultsRandomProperties,
                                                     dicoOfEconomyRandomVariables      : dicoOfEconomyRandomVariables,
                                                     dicoOfSocioEconomyRandomVariables : dicoOfSocioEconomyRandomVariables,
                                                     dicoOfKpiResults                  : dicoOfKpiResults)
        resultTable.append(currentRunResults)

        // Dernier run, créer les histogrammes et y ranger
        // les échantillons de KPIs si on est en mode Aléatoire
        if run == nbOfRuns {
            KpiArray.generateHistograms(ofTheseKPIs: &self.kpis)
        }
    }

    /// Exécuter une simulation Déterministe ou Aléatoire
    /// - Parameters:
    ///   - nbOfYears: nombre d'années à construire
    ///   - nbOfRuns: nombre de run à calculer (> 1: mode aléatoire)
    ///   - family: la famille
    ///   - patrimoine: le patrimoine
    ///
    func compute(nbOfYears                 : Int,
                 nbOfRuns                  : Int,
                 withFamily family         : Family,
                 withPatrimoine patrimoine : Patrimoin) {

        defer {
            // jouer le son à la fin de la simulation
            Simulation.player.seek(to: .zero)
            Simulation.player.play()
        }

        //propriétés indépendantes du nombre de run
        firstYear   = Date.now.year
        lastYear    = firstYear + nbOfYears - 1

        let monteCarlo = nbOfRuns > 1
        var dicoOfEconomyRandomVariables      = Economy.DictionaryOfRandomVariable()
        var dicoOfSocioEconomyRandomVariables = SocioEconomy.DictionaryOfRandomVariable()

        if monteCarlo {
            // remettre à zéro les historiques des tirages aléatoires
            resetAllRandomHistories()
            // remettre à zéro la table de résultat
            resultTable = SimulationResultTable()
        }

        // sauvegarder l'état initial du patrimoine pour y revenir à la fin de chaque run
        patrimoine.save()

        // calculer tous les runs
        for run in 1...nbOfRuns {
            currentRunNb = run
            SimulationLogger.shared.log(run      : currentRunNb,
                                        logTopic : LogTopic.simulationEvent,
                                        message  : "Début : \(firstYear!)")

            // re-générer les propriétés aléatoires à chaque run si on est en mode Aléatoire
            if monteCarlo {
                nextRandomProperties(family,
                                     &dicoOfEconomyRandomVariables,
                                     &dicoOfSocioEconomyRandomVariables)
            }

            // Réinitialiser la simulation
            reset(includingKPIs: run == 1 ? true : false)

            // construire les comptes sociaux du patrimoine de la famille
            let dicoOfKpiResults = socialAccounts.build(run            : run,
                                                        nbOfYears      : nbOfYears,
                                                        withFamily     : family,
                                                        withPatrimoine : patrimoine,
                                                        withKPIs       : &kpis,
                                                        withMode       : mode)
            if monteCarlo {
                closeMonteCarloRun(family,
                                   run,
                                   dicoOfEconomyRandomVariables,
                                   dicoOfSocioEconomyRandomVariables,
                                   dicoOfKpiResults,
                                   nbOfRuns)
            }

            patrimoine.restore()
        }

        isComputed  = true
        isSaved     = false
    }

    func replay(thisRun                   : SimulationResultLine,
                withFamily family         : Family,
                withPatrimoine patrimoine : Patrimoin) {
        // propriétés indépendantes du nombre de run
        guard let nbOfYears = lastYear - firstYear + 1 else {
            fatalError()
        }
        firstYear   = Date.now.year
        lastYear    = firstYear + nbOfYears - 1

        currentRunNb = 1
        SimulationLogger.shared.log(run      : currentRunNb,
                                    logTopic : LogTopic.simulationEvent,
                                    message  : "Début : \(firstYear!)")

        // fixer tous les paramètres du run à rejouer
        try! Economy.model.setRandomValue(to                 : thisRun.dicoOfEconomyRandomVariables,
                                          withMode           : mode,
                                          simulateVolatility : UserSettings.shared.simulateVolatility,
                                          firstYear          : firstYear!,
                                          lastYear           : lastYear!)
        SocioEconomy.model.setRandomValue(to: thisRun.dicoOfSocioEconomyRandomVariables)
        family.members.forEach { person in
            if let adult = person as? Adult {
                adult.ageOfDeath           = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.ageOfDeath
                adult.nbOfYearOfDependency = thisRun.dicoOfAdultsRandomProperties[adult.displayName]!.nbOfYearOfDependency
            }
        }

        // Réinitialiser la simulation
        self.reset(includingKPIs: false)

        // construire les comptes sociaux du patrimoine de la famille
        _ = socialAccounts.build(run            : 0,
                                 nbOfYears      : nbOfYears,
                                 withFamily     : family,
                                 withPatrimoine : patrimoine,
                                 withKPIs       : &kpis,
                                 withMode       : mode)
        patrimoine.restore()

        isComputed  = true
        isSaved     = false
    }

    /// Sauvegarder les résultats de simulation dans des fchier CSV
    func save() {
        /// - un fichier pour le Cash Flow
        /// - un fichier pour le Bilan
        socialAccounts.save(simulationTitle: title,
                            withMode       : mode)

        /// - un fichier pour le tableau de résultat de Monté-Carlo
        resultTable.save(simulationTitle: title)
    }
}
