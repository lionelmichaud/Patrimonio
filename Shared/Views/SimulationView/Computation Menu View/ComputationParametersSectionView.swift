//
//  ComputationParametersSectionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 21/11/2021.
//

import SwiftUI
import RetirementModel
import LifeExpense
import PatrimoineModel

struct ComputationParametersSectionView : View {
    @EnvironmentObject private var simulation : Simulation
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        Section(header: Text("Paramètres de Simulation").font(.headline)) {
            // choix du Titre et Note
            VStack {
                HStack {
                    Text("Titre")
                        .frame(width: 70, alignment: .leading)
                    TextField("", text: $simulation.title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                LabeledTextEditor(label: "Note", text: $simulation.note)
            }
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
            // Choix des paramètres des KPIs
            NavigationLink(destination: KpisParametersEditView()) {
                Text("Critères de performances")
                    .foregroundColor(.accentColor)
            }
        }
        
    }
}

//struct ComputationParametersSectionView_Previews: PreviewProvider {
//    static var previews: some View {
//        ComputationParametersSectionView()
//    }
//}
