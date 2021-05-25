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
        Form {
            if let activeDossier = dataStore.activeDossier {
                DossierPropertiesView(dossier: activeDossier,
                                      sectionHeader: "Dossier chargé")
            }
            Text("resourcePath: \n" + Bundle.main.resourcePath!)
            Text("Application: \n" + Folder.application!.path)
            Text("Home: \n" +        Folder.home.path)
            Text("Tempates: \n" +  (Dossier.templates?.folder?.path ?? "introuvable"))
            Text("Documents: \n" + (Folder.documents?.path ?? "introuvable"))
            Text("Library: \n" +   (Folder.library?.path ?? "introuvable"))
            Text("temporary: \n" + Folder.temporary.path)
            Text("current: \n" + Folder.current.path)
            Text("root: \n" +    Folder.root.path)
        }
    }
}

struct DossierSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        DossierSummaryView()
    }
}
