//
//  DossierDetailView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import SwiftUI

struct DossierDetailView: View {
    var dossier: Dossier
    
    var body: some View {
        Form {
            Text(dossier.name).font(.headline)
            Text(dossier.note).multilineTextAlignment(.leading)
            LabeledText(label: "Date de céation",
                        text : dossier.dateCreation)
            LabeledText(label: "Date de dernière modification",
                        text : dossier.dateModification)
            LabeledText(label: "Nom du directory associé",
                        text : dossier.folderName)
        }
    }
}

struct DossierDetailView_Previews: PreviewProvider {
    static let dossier = Dossier()
        .namedAs("Nom du dossier")
        .annotatedBy("note ligne 1\nligne 2")
        .createdOn(Date.now)
    static var previews: some View {
        DossierDetailView(dossier: dossier)
            .previewLayout(.sizeThatFits)
    }
}
