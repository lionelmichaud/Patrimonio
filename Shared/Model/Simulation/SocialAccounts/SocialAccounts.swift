import Foundation
import os
import AppFoundation
import Statistics
import Files
import ModelEnvironment

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "Model.SocialAccounts")

/// Combinaisons possibles de séries sur le graphique de Bilan
enum BalanceCombination: String, PickableEnum {
    case assets      = "Actif"
    case liabilities = "Passif"
    case both        = "Tout"

    var pickerString: String {
        return self.rawValue
    }
}

/// Combinaisons possibles de séries sur le graphique de CashFlow
enum CashCombination: String, PickableEnum {
    case revenues = "Revenu"
    case expenses = "Dépense"
    case both     = "Tout"

    var pickerString: String {
        return self.rawValue
    }
}

// MARK: - Comptes sociaux

/// Comptes sociaux: Table de Compte de résultat annuels + Bilans annuels
struct SocialAccounts {
    
    // MARK: - Properties
    
    var cashFlowArray = CashFlowArray()
    var balanceArray  = BalanceSheetArray()
    var firstYear     = Date.now.year
    var lastYear      = Date.now.year
    // les successions légales
    var legalSuccessions   : [Succession] = []
    // les transmissions d'assurances vie
    var lifeInsSuccessions : [Succession] = []

    // MARK: - Computed Properties
    
    var isEmpty: Bool {
        cashFlowArray.isEmpty || balanceArray.isEmpty
    }

    // MARK: - Methods
    
    fileprivate func setKpiValue(kpiEnum        : SimulationKPIEnum,
                                 value          : Double,
                                 kpiDefinitions : inout KpiArray,
                                 kpiResults     : inout DictionaryOfKpiResults,
                                 simulationMode : SimulationModeEnum) {
        kpiDefinitions[kpiEnum.id].record(value, withMode: simulationMode)
        kpiResults[kpiEnum] =
            KpiResult(value : value,
                      objectiveIsReached : kpiDefinitions[kpiEnum.id].objectiveIsReached(for : value))
    }
    
    /// Mémorise le niveau le + bas atteint par les actifs financiers (hors immobilier physique) au cours du run
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - kpis: les KPI à utiliser
    ///   - simulationMode: mode de simluation en cours
    fileprivate func computeMinimumAssetKpiValue(withKPIs kpiDefinitions : inout KpiArray,
                                                 withMode simulationMode : SimulationModeEnum,
                                                 kpiResults              : inout DictionaryOfKpiResults) {
        let minBalanceSheetLine = balanceArray.min { a, b in
            a.netAdultsFinancialAssets < b.netAdultsFinancialAssets
        }
        // KPI 3: mémoriser le minimum d'actif financier net au cours du temps
        setKpiValue(kpiEnum        : .minimumAsset,
                    value          : minBalanceSheetLine!.netAdultsFinancialAssets,
                    kpiDefinitions : &kpiDefinitions,
                    kpiResults     : &kpiResults,
                    simulationMode : simulationMode)
    }

    /// Gérer les KPI quand il n'y a plus de Cash => on arrête la simulation et on calcule la valeur des KPIs
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - year: année du run courant
    ///   - withKPIs: les KPI à utiliser
    ///   - kpiResults: valeur des KPIs pour le run courant
    fileprivate func computeKpisAtZeroCashAvailable // swiftlint:disable:this function_parameter_count
    (year                    : Int,
     withFamily family       : Family,
     withKPIs kpiDefinitions : inout KpiArray,
     kpiResults              : inout DictionaryOfKpiResults,
     withMode simulationMode : SimulationModeEnum,
     withbalanceSheetLine    : BalanceSheetLine?) {
        customLog.log(level: .info, "Arrêt de la construction de la table en \(year, privacy: .public) de Comptes sociaux: à court de cash dans \(Self.self, privacy: .public)")

        // Actif Net (hors immobilier physique)
        let netFinancialAssets = withbalanceSheetLine?.netAdultsFinancialAssets ?? 0
        customLog.log(level: .info, "netFinancialAssets: \(netFinancialAssets.k€String, privacy: .public)")

        // mémoriser le montant de l'Actif financier Net (hors immobilier physique)
        switch family.nbOfAdultAlive(atEndOf: year) {
            case 2:
                // il reste 2 adultes vivants
                ()

            case 1:
                // il reste 1 seul adulte vivant
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    // un des deux adulte est décédé cette année
                    setKpiValue(kpiEnum        : .assetAt1stDeath,
                                value          : netFinancialAssets,
                                kpiDefinitions : &kpiDefinitions,
                                kpiResults     : &kpiResults,
                                simulationMode : simulationMode)
                }

            case 0:
                // il ne plus d'adulte vivant
                ()
                
            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans \(Self.self)")
        }
        /// KPI n°3 : on est arrivé à la fin de la simulation car il n'y a plus de revenu généré par les Free Investements
        /// mais il peut éventuellement rester d'autres actifs (immobilier de rendement...)
        // TODO: - il faudrait définir un KPI spécifique "plus assez de revenu pour survivre" au lieu de faire comme s'il ne restait plus d'actif net
        setKpiValue(kpiEnum        : .minimumAsset,
                    value          : 0,
                    kpiDefinitions : &kpiDefinitions,
                    kpiResults     : &kpiResults,
                    simulationMode : simulationMode)
    }
    
    /// Gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
    /// - Note:
    ///   - Les biens sont sont évalués à leur valeur selon la méthode de calcul des préférences utilisateur
    /// - Parameters:
    ///   - year: année du run courant
    ///   - withKPIs: les KPI à utiliser
    ///   - kpiResults: valeur des KPIs pour le run courant
    fileprivate func computeKpisAtDeath (year                               : Int, // swiftlint:disable:this function_parameter_count
                                         withFamily family                  : Family,
                                         withKPIs kpiDefinitions            : inout KpiArray,
                                         kpiResults                         : inout DictionaryOfKpiResults,
                                         withMode simulationMode            : SimulationModeEnum,
                                         balanceSheetLineBeforeTransmission : BalanceSheetLine?,
                                         balanceSheetLineAfterTransmission  : BalanceSheetLine) {
        // Dernier Actif Net (après transmission en cas de décès dans l'année) (hors immobilier physique)
        let netFinancialAssetsAfterTransmission = balanceSheetLineAfterTransmission.netAdultsFinancialAssets
        
        // Actif Net précédent (avant transmission en cas de décès dans l'année) (hors immobilier physique))
        let netFinancialAssetsBeforeTransmission = balanceSheetLineBeforeTransmission?.netAdultsFinancialAssets ?? netFinancialAssetsAfterTransmission

        switch family.nbOfAdultAlive(atEndOf: year) {
            case 1:
                /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique) du conjoint survivant après transmission
                setKpiValue(kpiEnum        : .assetAt1stDeath,
                            value          : netFinancialAssetsAfterTransmission,
                            kpiDefinitions : &kpiDefinitions,
                            kpiResults     : &kpiResults,
                            simulationMode : simulationMode)

            case 0:
                if family.nbOfAdultAlive(atEndOf: year-1) == 2 {
                    /// KPI n°1: décès du premier conjoint et mémoriser la valeur du KPI
                    // mémoriser le montant de l'Actif Net (hors immobilier physique) des parents avant transmission
                    setKpiValue(kpiEnum        : .assetAt1stDeath,
                                value          : netFinancialAssetsBeforeTransmission,
                                kpiDefinitions : &kpiDefinitions,
                                kpiResults     : &kpiResults,
                                simulationMode : simulationMode)
                }
                /// KPI n°2: décès du second conjoint et mémoriser la valeur du KPI
                // mémoriser le montant de l'Actif Net (hors immobilier physique) des parents avant transmission
                setKpiValue(kpiEnum        : .assetAt2ndtDeath,
                            value          : netFinancialAssetsBeforeTransmission,
                            kpiDefinitions : &kpiDefinitions,
                            kpiResults     : &kpiResults,
                            simulationMode : simulationMode)
                /// KPI n°3 : on est arrivé à la fin de la simulation
                // rechercher le minimum d'actif financier au cours du temps (hors immobilier physique)
                computeMinimumAssetKpiValue(withKPIs   : &kpiDefinitions,
                                            withMode   : simulationMode,
                                            kpiResults : &kpiResults)
                
            default:
                // ne devrait jamais se produire
                customLog.log(level: .fault, "Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year), privacy: .public) dans \(Self.self, privacy: .public)")
                fatalError("Nombre d'adulte survivants inattendu: \(family.nbOfAdultAlive(atEndOf: year)) dans  \(Self.self)")
        }
    }
    
    // MARK: - Construction de la table des comptes sociaux = Bilan + CashFlow
    
    /// Construire la table de comptes sociaux au fil des années
    /// - Parameters:
    ///   - run: numéro du run en cours de calcul
    ///   - nbOfYears: nombre d'années à construire
    ///   - family: la famille dont il faut faire le bilan
    ///   - patrimoine: le patrimoine de la famille
    ///   - kpis: les KPI à utiliser et à dont il faut mettre à jour l'histogramme pendant le run
    ///   - simulationMode: mode de simluation en cours
    /// - Returns: Résultats obtenus pour les KPI
    mutating func build(run                       : Int, // swiftlint:disable:this function_parameter_count
                        nbOfYears                 : Int,
                        withFamily family         : Family,
                        withPatrimoine patrimoine : Patrimoin,
                        withKPIs kpis             : inout KpiArray,
                        withMode simulationMode   : SimulationModeEnum,
                        using model               : Model) -> DictionaryOfKpiResults {
        
        //-------------------------------------------------------------------------------------------
        firstYear = Date.now.year
        lastYear  = firstYear + nbOfYears - 1
        cashFlowArray.reserveCapacity(nbOfYears)
        balanceArray.reserveCapacity(nbOfYears)
        
        var kpiResults = DictionaryOfKpiResults()
        
        for year in firstYear ... lastYear {
            // construire la ligne annuelle de Cash Flow
            //------------------------------------------
            /// gérer le report de revenu imposable
            var lastYearDelayedTaxableIrppRevenue: Double
            if let lastLine = cashFlowArray.last { // de l'année précédente, s'il y en a une
                lastYearDelayedTaxableIrppRevenue = lastLine.taxableIrppRevenueDelayedToNextYear.value(atEndOf: year - 1)
            } else {
                lastYearDelayedTaxableIrppRevenue = 0
            }
            
            /// ajouter une nouvelle ligne pour une nouvelle année
            do {
                let newCashFlowLine = try CashFlowLine(run                                   : run,
                                                       withYear                              : year,
                                                       withFamily                            : family,
                                                       withPatrimoine                        : patrimoine,
                                                       taxableIrppRevenueDelayedFromLastyear : lastYearDelayedTaxableIrppRevenue,
                                                       using                                 : model)
                cashFlowArray.append(newCashFlowLine)
                // ajouter les éventuelles successions survenues pendant l'année à la liste globale
                legalSuccessions   += newCashFlowLine.successions
                // ajouter les éventuelles transmissions d'assurance vie survenues pendant l'année à la liste globale
                lifeInsSuccessions += newCashFlowLine.lifeInsSuccessions
            } catch {
                /// il n'y a plus de Cash => on arrête la simulation
                lastYear = year
                // on calcule les KPI sur la base du dernier bilan connu (fin de l'année précédente)
                computeKpisAtZeroCashAvailable(year                 : year,
                                               withFamily           : family,
                                               withKPIs             : &kpis,
                                               kpiResults           : &kpiResults,
                                               withMode             : simulationMode,
                                               withbalanceSheetLine : balanceArray.last)
                SimulationLogger.shared.log(run      : run,
                                            logTopic : LogTopic.simulationEvent,
                                            message  : "Fin du run: à cours de cash en \(year)")
                return kpiResults // arrêter la construction de la table
            }

            // construire la ligne annuelle de Bilan de fin d'année
            //-----------------------------------------------------
            let newBalanceSheetLine = BalanceSheetLine(year            : year,
                                                       withMembersName : family.membersName,
                                                       withAdultsName  : family.adultsName,
                                                       withAssets      : patrimoine.assets.allOwnableItems,
                                                       withLiabilities : patrimoine.liabilities.allOwnableItems)
            
            if family.nbOfAdultAlive(atEndOf: year) < family.nbOfAdultAlive(atEndOf: year-1) {
                // décès d'un adulte en cours d'année
                // gérer les KPI n°1, 2, 3 au décès de l'un ou des 2 conjoints
                // attention: à ce stade les transmissions de succession ont déjà été réalisées
                computeKpisAtDeath(year                               : year,
                                   withFamily                         : family,
                                   withKPIs                           : &kpis,
                                   kpiResults                         : &kpiResults,
                                   withMode                           : simulationMode,
                                   balanceSheetLineBeforeTransmission : balanceArray.last,
                                   balanceSheetLineAfterTransmission  : newBalanceSheetLine)
            }
            
            balanceArray.append(newBalanceSheetLine)
            
            if family.nbOfAdultAlive(atEndOf: year) == 0 {
                // il n'y a plus d'adulte vivant à la fin de l'année
                // on arrête la simulation après avoir clos les dernières successions
                lastYear = year
                SimulationLogger.shared.log(run      : run,
                                            logTopic : LogTopic.simulationEvent,
                                            message  : "Fin du run: plus d'adulte en vie en \(year)")
                return kpiResults // arrêter la construction de la table
            }
        }
        
        /// KPI n°3 : on est arrivé à la fin de la simulation
        // rechercher le minimum d'actif financier net au cours du temps
        computeMinimumAssetKpiValue(withKPIs   : &kpis,
                                    withMode   : simulationMode,
                                    kpiResults : &kpiResults)
        SimulationLogger.shared.log(run      : run,
                                    logTopic : LogTopic.simulationEvent,
                                    message  : "Fin du run: date de fin de run atteinte en \(lastYear)")
        return kpiResults
    }
    
    /// Générer les String au format CSV à partir des résultats
    /// de la dernière simulation réalisée
    ///
    /// - un fichier pour le Cash Flow
    /// - un fichier pour le Bilan
    /// - un fichier pour les Successions
    ///
    /// - Parameter mode: mode de simulation utilisé lors de la dernière simulation
    /// - Returns: dictionnaire [Nom de fichier : CSV string]
    func lastSimulationResultCsvStrings(using model  : Model,
                                        withMode mode: SimulationModeEnum) -> [String:String] {
        //    (balanceSheetCSV : String,
        //     cashFlowCSV     : String,
        //     successionsCSV  : String) {
        var dico = [String:String]()
        // construction du tableau de bilans annnuels au format CSV
        dico[FileNameCst.kBalanceSheetCSVFileName] =
            CsvBuilder.balanceSheetCSV(from     : balanceArray,
                                       using    : model,
                                       withMode : mode)
        // construction du tableau de cash flow annnuels au format CSV
        dico[FileNameCst.kCashFlowCSVFileName] =
            CsvBuilder.cashFlowCSV(from     : cashFlowArray,
                                   withMode : mode)
        // construction du tableau des successions
        dico[FileNameCst.kSuccessionsCSVFileName]  =
            String(describing: CsvSuccessionsVisitor(successions: legalSuccessions + lifeInsSuccessions))
        
        return dico
    }
}
