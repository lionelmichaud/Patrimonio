//
//  DossierPropertiesView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/05/2021.
//

import SwiftUI

struct DossierPropertiesView: View {
    var dossier: Dossier
    var sectionHeader: String
    
    var body: some View {
        Section(header: Text(sectionHeader)) {
            Text(dossier.name).font(.headline)
            if dossier.note.isNotEmpty {
                Text(dossier.note).multilineTextAlignment(.leading)
            }
            LabeledText(label: "Date de céation",
                        text : dossier.dateCreationStr)
            LabeledText(label: "Date de dernière modification",
                        text : "\(dossier.dateModificationStr) à \(dossier.hourModificationStr)")
            LabeledText(label: "Nom du directory associé",
                        text : dossier.folderName)
        }
    }
}

struct DossierPropertiesView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            DossierPropertiesView(dossier: Dossier()
                                    .namedAs("Un nom")
                                    .annotatedBy("Une note")
                                    .activated()
                                    .createdOn(),
                                  sectionHeader: "Header")
        }
    }
}
