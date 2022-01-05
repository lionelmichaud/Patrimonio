//
//  AppVersionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/04/2021.
//

import SwiftUI
import AppFoundation
import Files
import Persistence

struct AppVersionView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(AppVersion.shared.name ?? "Patrimonio")
                .font(.title)
                .fontWeight(.heavy)
                .frame(maxWidth: .infinity)
            Text("Version: \(AppVersion.shared.theVersion ?? "?")")
                .font(.title3)
            if let date = AppVersion.shared.date {
                Text(date, style: Text.DateStyle.date)
                    .font(.title3)
            }
            if let comment = AppVersion.shared.comment {
                Text(comment)
                    .font(.title3)
            }
            
            Form {
                Section {
                    // Historique des révisions
                    RevisionHistoryView(revisions: AppVersion.shared.revisionHistory)
                }
                Section {
                    // Liste des directories utilisées par l'application
                    DirectoriesListView()
                }
            }
        }
        .navigationBarHidden(true)
    }
}

struct RevisionHistoryView: View {
    var revisions: [Version]
    @State private var expanded = true
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $expanded,
            content: {
                ForEach(revisions, id: \.self) { revision in
                    RevisionView(revision: revision)
                }
            },
            label: {
                Text("HISTORIQUE DES REVISIONS").font(.headline)
            })
    }
}

struct RevisionView: View {
    var revision: Version

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let version = revision.version {
                    Text(version)
                        .fontWeight(.heavy)
                }
                if let date = revision.date {
                    Text("(") + Text(date, style: Text.DateStyle.date) + Text(") :")
                }
            }
            .font(.subheadline)
            
            Text(revision.comment ?? "")
                .multilineTextAlignment(.leading)
                .lineSpacing(10.0)
                .padding(.leading)
        }
    }
}

struct DirectoriesListView: View {
    @State private var expanded = false

    var body: some View {
        DisclosureGroup(
            isExpanded: $expanded,
            content: {
                Text("resourcePath: \n").font(.headline) + Text(Bundle.main.resourcePath!)
                Text("Application: \n").font(.headline) + Text(Folder.application!.path)
                Text("Home: \n").font(.headline) +      Text(Folder.home.path)
                Text("Tempates: \n").font(.headline) +  Text((Dossier.templates?.folder?.path ?? "introuvable"))
                Text("Documents: \n").font(.headline) + Text((Folder.documents?.path ?? "introuvable"))
                Text("Library: \n").font(.headline) +   Text((Folder.library?.path ?? "introuvable"))
                Text("temporary: \n").font(.headline) + Text(Folder.temporary.path)
            },
            label: {
                Text("REPERTOIRES DE L'APPLICATION").font(.headline)
            })
    }
}

struct AppVersionView_Previews: PreviewProvider {
    static var previews: some View {
        AppVersionView()
    }
}

struct RevisionView_Previews: PreviewProvider {
    static var previews: some View {
        RevisionView(revision: Version()
                        .versioned("2.0.0")
                        .commented(with: "Descriptif de version"))
            .previewLayout(.sizeThatFits)
    }
}

struct RevisionHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        RevisionHistoryView(revisions: AppVersion.shared.revisionHistory)
            .previewLayout(.sizeThatFits)
    }
}

struct DirectoriesListView_Previews: PreviewProvider {
    static var previews: some View {
        DirectoriesListView()
        
    }
}
