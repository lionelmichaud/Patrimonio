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
    @Binding var betaRandomizer: ModelRandomizer<BetaRandomGenerator>
    @State var minX: Double
    @State var maxX: Double

    var body: some View {
        VStack {
            VersionEditableViewInForm(version: $betaRandomizer.version)
                .frame(maxHeight: betaRandomizer.version.comment == nil ? 40 : 80)

            HStack {
                Stepper(value : $minX,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        Text("\(minX.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.padding(.trailing)
                .onChange(of: minX) { value in
                    betaRandomizer.rndGenerator.minX = value
                    betaRandomizer.rndGenerator.initialize()
                }
                
                Stepper(value : $maxX,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Maximum")
                        Spacer()
                        Text("\(maxX.percentString(digit: 1)) %").foregroundColor(.secondary)
                    }
                }.padding(.trailing)
                .onChange(of: maxX) { value in
                    betaRandomizer.rndGenerator.maxX = value
                    betaRandomizer.rndGenerator.initialize()
                }
                
                Stepper(value : $betaRandomizer.rndGenerator.alpha,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Alpha")
                        Spacer()
                        Text("\(betaRandomizer.rndGenerator.alpha as NSNumber, formatter: decimalFormatter)").foregroundColor(.secondary)
                    }
                }.padding(.trailing)
                .onChange(of: betaRandomizer.rndGenerator.alpha) { _ in
                    betaRandomizer.rndGenerator.initialize()
                }
                
                Stepper(value : $betaRandomizer.rndGenerator.beta,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Beta")
                        Spacer()
                        Text("\(betaRandomizer.rndGenerator.beta as NSNumber, formatter: decimalFormatter)").foregroundColor(.secondary)
                    }
                }.onChange(of: betaRandomizer.rndGenerator.beta) { _ in
                    betaRandomizer.rndGenerator.initialize()
                }
            }
            .padding(.horizontal)
            
            BetaRandomizerView(randomizer: betaRandomizer)
        }
    }
    
    init(betaRandomizer: Binding<ModelRandomizer<BetaRandomGenerator>>) {
        self._betaRandomizer = betaRandomizer
        self._minX = State(initialValue: betaRandomizer.wrappedValue.rndGenerator.minX ?? 0)
        self._maxX = State(initialValue: betaRandomizer.wrappedValue.rndGenerator.maxX ?? 1)
    }
}

struct BetaRandomizerEditView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return BetaRandomizerEditView(betaRandomizer: .constant(modelTest.economyModel.randomizers.inflation))
    }
}
