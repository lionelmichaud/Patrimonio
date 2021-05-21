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
            Label("Sélectionner un dossier de travail dans le menu à gauche", systemImage: "folder.badge.person.crop")
            Text("ou")
            Label("Créer un nouveau dossier de travail dans le menu à gauche", systemImage: "folder.fill.badge.plus")
        }
        .font(.title)
    }
}

struct DossierHomeView_Previews: PreviewProvider {
    static var previews: some View {
        DossierHomeView()
    }
}
