//
//  DossierSummaryView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI

struct NoLoadedDossierView: View {
    var body: some View {
        VStack {
            Label("Sélectionner un dossier dans l'onglet Dossiers et le charger", systemImage: "folder.badge.person.crop")
            Text("ou")
            Label("Créer un nouveau dossier dans l'onglet Dossiers et le charger", systemImage: "folder.fill.badge.plus")
        }
        .font(.headline)
    }
}

struct DossierHomeView_Previews: PreviewProvider {
    static var previews: some View {
        NoLoadedDossierView()
    }
}
