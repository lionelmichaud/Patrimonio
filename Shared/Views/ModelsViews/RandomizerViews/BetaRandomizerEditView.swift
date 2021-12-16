//
//  BetaRandomizerEditView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 10/09/2021.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import Statistics
import Persistence

// MARK: - Deterministic View Model

class BetaRandomViewModel: ObservableObject {

    // MARK: - Properties

    @Published var isModified : Bool
    @Published var min   : Double = 0.0
    @Published var max   : Double = 0.0
    @Published var alpha : Double = 0.0
    @Published var beta  : Double = 0.0

    // MARK: - Initialization

    init(from randomizer: ModelRandomizer<BetaRandomGenerator>) {
        min   = randomizer.rndGenerator.minX!
        max   = randomizer.rndGenerator.maxX!
        alpha = randomizer.rndGenerator.alpha
        beta  = randomizer.rndGenerator.beta

        isModified = false
    }

    // MARK: - methods
    
    func update(_ randomizer: inout ModelRandomizer<BetaRandomGenerator>) {
        randomizer.rndGenerator.minX  = min
        randomizer.rndGenerator.maxX  = max
        randomizer.rndGenerator.alpha = alpha
        randomizer.rndGenerator.beta  = beta
        
        randomizer.rndGenerator.initialize()

        isModified = false
    }
    
    func updateFrom(_ randomizer: ModelRandomizer<BetaRandomGenerator>) {
        min   = randomizer.rndGenerator.minX!
        max   = randomizer.rndGenerator.maxX!
        alpha = randomizer.rndGenerator.alpha
        beta  = randomizer.rndGenerator.beta
        
        isModified = false
    }
}

struct BetaRandomizerEditView : View {
    let applyChangesToModel      : (_ viewModel: BetaRandomViewModel) -> Void
    let applyChangesToModelClone : (_ viewModel: BetaRandomViewModel, _ clone: Model) -> Void
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var simulation : Simulation
    @StateObject private var viewModel        : BetaRandomViewModel
    @State private var betaRandomizer         : ModelRandomizer<BetaRandomGenerator>
    private var initialBetaRandomizer         : ModelRandomizer<BetaRandomGenerator>!
    @State private var alertItem              : AlertItem?

    var body: some View {
        HStack {
            Stepper(value : $viewModel.min,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Minimum")
                    Spacer()
                    Text("\(viewModel.min.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.padding(.trailing)
            .onChange(of: viewModel.min) { value in
                betaRandomizer.rndGenerator.minX = value
                betaRandomizer.rndGenerator.initialize()
                viewModel.isModified = true
            }

            Stepper(value : $viewModel.max,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Maximum")
                    Spacer()
                    Text("\(viewModel.max.percentString(digit: 1)) %").foregroundColor(.secondary)
                }
            }.padding(.trailing)
            .onChange(of: viewModel.max) { value in
                betaRandomizer.rndGenerator.maxX = value
                betaRandomizer.rndGenerator.initialize()
                viewModel.isModified = true
            }

            Stepper(value : $viewModel.alpha,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Alpha")
                    Spacer()
                    Text("\(viewModel.alpha as NSNumber, formatter: decimalFormatter)").foregroundColor(.secondary)
                }
            }.padding(.trailing)
            .onChange(of: viewModel.alpha) { value in
                betaRandomizer.rndGenerator.alpha = value
                betaRandomizer.rndGenerator.initialize()
                viewModel.isModified = true
            }
            
            Stepper(value : $viewModel.beta,
                    in    : 0 ... 10,
                    step  : 0.1) {
                HStack {
                    Text("Beta")
                    Spacer()
                    Text("\(viewModel.beta as NSNumber, formatter: decimalFormatter)").foregroundColor(.secondary)
                }
            }.onChange(of: viewModel.beta) { value in
                betaRandomizer.rndGenerator.beta = value
                betaRandomizer.rndGenerator.initialize()
                viewModel.isModified = true
            }
        }
        .padding(.horizontal)

        BetaRandomizerView(randomizer: betaRandomizer)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    DiskButton(text   : "Enregistrer comme Modèle",
                               action : applyChangesToTemplate)
                }
                ToolbarItem(placement: .automatic) {
                    FolderButton(action : applyChanges)
                        .disabled(!changeOccured)
                }
            }
            .onAppear {
                viewModel.updateFrom(betaRandomizer)
            }
            .alert(item: $alertItem, content: createAlert)
    }

    // MARK: - Properties

    var changeOccured: Bool {
        viewModel.isModified
    }

    // MARK: - Initialization

    init(with betaRandomizer     : ModelRandomizer<BetaRandomGenerator>,
         applyChangesToModel     : @escaping (_ viewModel : BetaRandomViewModel) -> Void,
         applyChangesToModelClone: @escaping (_ viewModel : BetaRandomViewModel, _ clone : Model) -> Void) {
        _viewModel                    = StateObject(wrappedValue: BetaRandomViewModel(from : betaRandomizer))
        _betaRandomizer               = State(initialValue: betaRandomizer)
        initialBetaRandomizer         = betaRandomizer
        self.applyChangesToModel      = applyChangesToModel
        self.applyChangesToModelClone = applyChangesToModelClone
    }
    
    /// Appliquer la modification au projet ouvert (en mémoire)
    ///
    /// - Warning:
    ///     Ne suvegarde PAS la modification sur disque
    ///
    func applyChanges() {
        alertItem =
            AlertItem(title         : Text("Dossier Ouvert"),
                      message       : Text("Voulez-vous appliquer les modifications effectuées au dossier ouvert ?"),
                      primaryButton : .default(Text("Appliquer")) {
                        // notifier de l'application de changements au modèle
                        applyChangesToModel(viewModel)
                        // invalider les résultats de simulation existants
                        simulation.notifyComputationInputsModification()
                      },
                      secondaryButton: .cancel(Text("Revenir")) {
                        viewModel.updateFrom(initialBetaRandomizer)
                      })
    }
    
    /// Enregistrer la modification dans le répertoire Template (sur disque)
    ///
    /// - Warning:
    ///     N'applique PAS la modification au projet ouvert (en mémoire)
    ///
    func applyChangesToTemplate() {
        alertItem =
            AlertItem(title         : Text("Modèle"),
                      message       : Text("Voulez-vous appliquer les modifications effectuées au modèle ?"),
                      primaryButton : .default(Text("Appliquer")) {
                        guard let templateFolder = PersistenceManager.templateFolder() else {
                            alertItem =
                                AlertItem(title         : Text("Répertoire 'Modèle' absent"),
                                          dismissButton : .default(Text("OK")))
                            return
                        }
                        
                        // notifier l'application de changements au modèle
                        // créer une copie du modèle
                        let copy = Model(from: model)
                        let wasModified = viewModel.isModified
                        applyChangesToModelClone(viewModel, copy)
                        viewModel.isModified = wasModified

                        do {
                            try copy.saveAsJSON(toFolder: templateFolder)
                        } catch {
                            alertItem =
                                AlertItem(title         : Text("Echec de l'enregistrement"),
                                          dismissButton : .default(Text("OK")))
                        }
                      },
                      secondaryButton: .cancel())
    }
}

struct BetaRandomizerEditView_Previews: PreviewProvider {
    static func applyChanges(_ viewModel : BetaRandomViewModel) {}
    static func applyChangesToModelClone(_ viewModel : BetaRandomViewModel, _ clone: Model) {}

    static var previews: some View {
        loadTestFilesFromBundle()
        return BetaRandomizerEditView(with              : modelTest.economyModel.randomizers.inflation,
                               applyChangesToModel      : applyChanges,
                               applyChangesToModelClone : applyChangesToModelClone)
            .environmentObject(simulationTest)
    }
}
