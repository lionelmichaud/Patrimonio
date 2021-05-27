//
//  DossierSummaryView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI

struct DossierHomeView: View {
    var body: some View {
        VStack {
            Label("Sélectionner un dossier dans le menu à gauche et le charger", systemImage: "folder.badge.person.crop")
            Text("ou")
            Label("Créer un nouveau dossier dans le menu à gaucheet le charger", systemImage: "folder.fill.badge.plus")
        }
        .font(.headline)
    }
}

struct DossierHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DossierHomeView()
    }
}
