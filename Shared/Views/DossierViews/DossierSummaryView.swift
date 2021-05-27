//
//  DossierSummaryView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Files

struct DossierSummaryView: View {
    @EnvironmentObject var dataStore : Store
    
    var body: some View {
        if let activeDossier = dataStore.activeDossier {
            Form {
                DossierPropertiesView(dossier: activeDossier,
                                      sectionHeader: "Dossier en cours")
            }
        } else {
            DossierHomeView()
        }
    }
}

struct DossierSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        DossierSummaryView()
    }
}
