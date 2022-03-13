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
import HelpersView

struct BetaRandomizerEditView : View {
    @Binding var betaRandomizer: ModelRandomizer<BetaRandomGenerator>
    @State var minX: Double
    @State var maxX: Double

    var body: some View {
        VStack(alignment: .leading) {
            // édition de la version
            VersionEditableViewInForm(version: $betaRandomizer.version)
                .frame(maxHeight: betaRandomizer.version.comment == nil ? 30 : 60)
                .padding(.leading)

            // édition des paramètres de la loi beta
            HStack {
                Stepper(value : $minX,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        Text("\(minX.percentString(digit: 1))")
                            .foregroundColor(.secondary)
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
                        Text("\(maxX.percentString(digit: 1))")
                            .foregroundColor(.secondary)
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
            
            // graphique
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
