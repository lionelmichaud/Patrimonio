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

    var body: some View {
        Form {
            Section(footer: Text("Sélectionner les données à partager")) {
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
        }
        .navigationTitle(Text("Export"))
    }
}

struct ExportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportSettingsView()
    }
}
