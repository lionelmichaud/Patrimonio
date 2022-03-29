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
    let updateDependenciesToModel: ( ) -> Void
    @Transac var betaRandomizer: ModelRandomizer<BetaRandomGenerator>

    var body: some View {
        VStack(alignment: .leading) {
            // édition de la version
            VersionEditableViewInForm(version: $betaRandomizer.version)
                .frame(maxHeight: betaRandomizer.version.comment == nil ? 30 : 60)
                .padding(.leading)

            // édition des paramètres de la loi beta
            HStack {
                Stepper(value : $betaRandomizer.rndGenerator.minX ?? 1.0,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Minimum")
                        Spacer()
                        Text(betaRandomizer.rndGenerator.minX!.percentString(digit: 1))
                            .foregroundColor(.secondary)
                    }
                }.padding(.trailing)
                .onChange(of: betaRandomizer.rndGenerator.minX) { _ in
                    betaRandomizer.rndGenerator.initialize()
                }
                
                Stepper(value : $betaRandomizer.rndGenerator.maxX ?? 1.0,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Maximum")
                        Spacer()
                        Text(betaRandomizer.rndGenerator.maxX!.percentString(digit: 1))
                            .foregroundColor(.secondary)
                    }
                }.padding(.trailing)
                .onChange(of: betaRandomizer.rndGenerator.maxX) { _ in
                    betaRandomizer.rndGenerator.initialize()
                }
                
                Stepper(value : $betaRandomizer.rndGenerator.alpha,
                        in    : 0 ... 10,
                        step  : 0.1) {
                    HStack {
                        Text("Alpha")
                        Spacer()
                        Text("\(betaRandomizer.rndGenerator.alpha as NSNumber, formatter: decimalFormatter)")
                            .foregroundColor(.secondary)
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
                        Text("\(betaRandomizer.rndGenerator.beta as NSNumber, formatter: decimalFormatter)")
                            .foregroundColor(.secondary)
                    }
                }.onChange(of: betaRandomizer.rndGenerator.beta) { _ in
                    betaRandomizer.rndGenerator.initialize()
                }
            }
            .padding(.horizontal)
            
            // graphique
            BetaRandomizerView(randomizer: betaRandomizer)
        }
        /// barre d'outils de la NavigationView
        .modelChangesToolbar2(subModel                  : $betaRandomizer,
                              updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct BetaRandomizerEditView_Previews: PreviewProvider {
    static var previews: some View {
        BetaRandomizerEditView(updateDependenciesToModel: { },
                               betaRandomizer: .init(source: TestEnvir.model.economyModel.randomizers.inflation))
    }
}
