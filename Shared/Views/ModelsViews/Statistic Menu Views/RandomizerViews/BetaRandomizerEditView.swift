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
}

struct BetaRandomizerEditView : View {
    @StateObject private var viewModel : BetaRandomViewModel
    @State private var betaRandomizer  : ModelRandomizer<BetaRandomGenerator>
    let applyChanges                   : (_ viewModel : BetaRandomViewModel) -> Void
    let applyChangesToTemplate         : (_ viewModel : BetaRandomViewModel) -> Void

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
        }.padding(.horizontal)

        BetaRandomizerView(randomizer: betaRandomizer)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    SaveToDiskButton(text   : "Modèle",
                                     action : { applyChangesToTemplate(viewModel) })
                }
                ToolbarItem(placement: .automatic) {
                    ApplyChangesButton(action : { applyChanges(viewModel) })
                        .disabled(!changeOccured)
                }
            }
    }

    // MARK: - Properties

    var changeOccured: Bool {
        viewModel.isModified
    }

    // MARK: - Initialization

    init(with betaRandomizer: ModelRandomizer<BetaRandomGenerator>,
         onApply: @escaping (_ viewModel : BetaRandomViewModel) -> Void,
         onSaveToTemplate: @escaping (_ viewModel : BetaRandomViewModel) -> Void) {
        _viewModel             = StateObject(wrappedValue: BetaRandomViewModel(from: betaRandomizer))
        _betaRandomizer        = State(initialValue: betaRandomizer)
        applyChanges           = onApply
        applyChangesToTemplate = onSaveToTemplate
    }
}

struct BetaRandomizerEditView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)
    static func applyChanges(viewModel : BetaRandomViewModel) {}
    static func applyChangesToTemplate(viewModel : BetaRandomViewModel) {}

    static var previews: some View {
        BetaRandomizerEditView(with             : model.economyModel.randomizers.inflation,
                               onApply          : applyChanges,
                               onSaveToTemplate : applyChangesToTemplate)
    }
}
