//
//  DossierPropertiesView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/05/2021.
//

import SwiftUI
import ModelEnvironment
import LifeExpense
import PatrimoineModel
import Persistence
import FamilyModel
import HelpersView

struct DossierPropertiesView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    var dossier: Dossier
    var sectionHeader: String

    var body: some View {
        Section(header: Text(sectionHeader)) {
            LabeledText(label: "Nom du dossier",
                        text : dossier.name)
            if dossier.isActive {
                LabeledText(label: "Etat",
                            text : savable() ? "Modifié et non sauvegardé" : "Sauvegardé")
            }
            if dossier.note.isNotEmpty {
                HStack {
                    Text("Note de dossier")
                        .padding(.trailing)
                    Spacer()
                    Text(dossier.note).multilineTextAlignment(.leading)
                }
            }
            LabeledText(label: "Date de céation",
                        text : dossier.dateCreationStr)
            LabeledText(label: "Date de dernière modification",
                        text : "\(dossier.dateModificationStr) à \(dossier.hourModificationStr)")
            LabeledText(label: "Nom du répertoire associé",
                        text : dossier.folderName)
        }
    }
    
    private func savable() -> Bool {
        family.isModified || expenses.isModified ||
            patrimoine.isModified || model.isModified ||
            simulation.isModified
    }
}

struct DossierPropertiesView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        let dossier = dataStoreTest.dossiers[0]
        return Form {
            DossierPropertiesView(dossier       : dossier,
                                  sectionHeader : "Header")
                .environmentObject(dataStoreTest)
                .environmentObject(modelTest)
                .environmentObject(uiStateTest)
                .environmentObject(familyTest)
                .environmentObject(expensesTest)
                .environmentObject(patrimoineTest)
                .environmentObject(simulationTest)
        }
    }
}
