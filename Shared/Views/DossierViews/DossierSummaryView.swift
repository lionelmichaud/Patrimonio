//
//  DossierSummaryView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 18/05/2021.
//

import SwiftUI
import Files

struct DossierSummaryView: View {
    var body: some View {
        VStack(alignment: .leading) {
            //Text(Dossier.templates?.name ?? "Dossier \(AppSettings.shared.templateDir) introuvable!")
            Text("resourcePath:" + Bundle.main.resourcePath!)
            Text("Application:" + Folder.application!.name)
            Text("tempates:" + Dossier.templates!.folder!.name)
            Text("Home:" + Folder.home.name)
            Text("Documents:" + Folder.documents!.name)
            Text("Library:" + Folder.library!.name)
            Text("temporary:" + Folder.temporary.name)
            Text("current:" + Folder.current.name)
            Text("root:" + Folder.root.name)
        }
    }
}

struct DossierSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        DossierSummaryView()
    }
}
