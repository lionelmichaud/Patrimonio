//
//  ExportSettingsView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/06/2021.
//

import SwiftUI
import Persistence

struct ExportSettingsView: View {
    @Preference(\.shareCsvFiles)   var shareCsvFiles
    @Preference(\.shareImageFiles) var shareImageFiles
    @Preference(\.shareAllDossierFilesWithSimuResults) var shareAllDossierFilesWithSimuResults
    @Preference(\.shareFamilyFilesWithSimuResults) var shareFamilyFilesWithSimuResults
    @Preference(\.shareExpensesFilesWithSimuResults) var shareExpensesFilesWithSimuResults
    @Preference(\.sharePatrimoineFilesWithSimuResults) var sharePatrimoineFilesWithSimuResults

    var body: some View {
        Form {
            Section(header: Text("Résulats de Simulation").font(.subheadline),
                    footer: Text("Sélectionner les résultats de simulation à partager")) {
                Toggle("Partager les résultas de simulation au format CSV",
                       isOn: $shareCsvFiles)
                    .onChange(of: shareCsvFiles) { newValue in
                        shareCsvFiles = newValue
                    }
                Toggle("Partager les copies d'écran",
                       isOn: $shareImageFiles)
                    .onChange(of: shareImageFiles) { newValue in
                        shareImageFiles = newValue
                    }
            }
            if shareCsvFiles || shareImageFiles {
                Section(header: Text("Contexte de Simulation").font(.subheadline),
                        footer: Text("Sélectionner les autres données à partager avec les résultats de simulation")) {
                    Toggle("Partager **tous** les fichiers de votre dossier (membres de la famille, dépenses et patrimoine associés)",
                           isOn: $shareAllDossierFilesWithSimuResults.animation(.easeInOut))
                        .onChange(of: shareAllDossierFilesWithSimuResults) { share in
                            if share {
                                shareFamilyFilesWithSimuResults     = true
                                shareExpensesFilesWithSimuResults   = true
                                sharePatrimoineFilesWithSimuResults = true
                            }
                        }
                    if !shareAllDossierFilesWithSimuResults {
                        Toggle("Partager les données des **membres** de la famille",
                               isOn: $shareFamilyFilesWithSimuResults)
                        .onChange(of: shareFamilyFilesWithSimuResults) { share in
                            if !share {
                                shareAllDossierFilesWithSimuResults = false
                            }
                        }
                        Toggle("Partager les données de **dépenses** de la famille",
                               isOn: $shareExpensesFilesWithSimuResults)
                        .onChange(of: shareExpensesFilesWithSimuResults) { share in
                            if !share {
                                shareAllDossierFilesWithSimuResults = false
                            }
                        }
                        Toggle("Partager les données sur le **patrimoniales** de la famille",
                               isOn: $sharePatrimoineFilesWithSimuResults)
                        .onChange(of: sharePatrimoineFilesWithSimuResults) { share in
                            if !share {
                                shareAllDossierFilesWithSimuResults = false
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Partage des Résultats de Simulation"))
    }
}

struct ExportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportSettingsView()
    }
}
