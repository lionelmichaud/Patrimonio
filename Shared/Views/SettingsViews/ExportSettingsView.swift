//
//  ExportSettingsView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/06/2021.
//

import SwiftUI
import Persistence

struct ExportSettingsView: View {
    @Binding var shareCsvFiles   : Bool
    @Binding var shareImageFiles : Bool

    var body: some View {
        Form {
            Section(footer: Text("Sélectionner les données à partager")) {
                Toggle("Partager les résultas de simulation au format CSV",
                       isOn: $shareCsvFiles)
                    .onChange(of: shareCsvFiles) { newValue in
                        UserSettings.shared.shareCsvFiles = newValue
                    }
                Toggle("Partager les copies d'écran",
                       isOn: $shareImageFiles)
                    .onChange(of: shareImageFiles) { newValue in
                        UserSettings.shared.shareImageFiles = newValue
                    }
            }
        }
    }
}

struct ExportSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ExportSettingsView(shareCsvFiles: .constant(true),
                           shareImageFiles: .constant(false))
    }
}
