//
//  ComputationParametersSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/11/2021.
//

import SwiftUI
import AppFoundation
import Persistence
import RetirementModel
import LifeExpense
import PatrimoineModel
import HelpersView

struct ComputationParametersSectionView : View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        GroupBox(label: Text("Paramètres de Simulation").font(.headline)) {
            // choix du Titre et Note
            VStack {
                HStack {
                    Text("Titre")
                        .frame(width: 70, alignment: .leading)
                    TextField("", text: $simulation.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: { simulation.title += " \(dataStore.activeDossier!.name)" },
                           label: { Image(systemName: "folder.fill.badge.person.crop") })
                    Button(action: { simulation.title += " le \(CalendarCst.now.stringShortDate)" },
                           label: { Image(systemName: "calendar") })
                }
                LabeledTextEditor(label: "Note", text: $simulation.note)
                    .frame(height: 60)
            }
            
            VStack {
                // choix du Nombre d'années
                HStack {
                    Text("Nombre d'années à calculer: ") + Text(String(Int(uiState.computationState.nbYears)))
                    Slider(value : $uiState.computationState.nbYears,
                           in    : 5 ... 55,
                           step  : 5,
                           onEditingChanged: {_ in
                           })
                }
                // choix du mode de simulation: cas spécifiques
                // sélecteur: Déterministe / Aléatoire
                CasePicker(pickedCase: $simulation.mode, label: "")
                    .pickerStyle(SegmentedPickerStyle())
                    .onChange(of: simulation.mode) { newMode in
                        Patrimoin.setSimulationMode(to: newMode)
                        Retirement.setSimulationMode(to: newMode)
                        LifeExpense.setSimulationMode(to: newMode)
                    }
                // choix du nombre de Runs
                switch simulation.mode {
                    case .deterministic:
                        EmptyView()
                        
                    case .random:
                        HStack {
                            Text("Nombre de run: ") + Text(String(Int(uiState.computationState.nbRuns)))
                            Slider(value : $uiState.computationState.nbRuns,
                                   in    : 100 ... 1000,
                                   step  : 100,
                                   onEditingChanged: {_ in
                                   })
                        }
                }
            }
        }.padding(.horizontal)
    }
}

struct ComputationParametersSectionView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return ComputationParametersSectionView()
            .preferredColorScheme(.dark)
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
            .environmentObject(TestEnvir.uiState)
    }
}
