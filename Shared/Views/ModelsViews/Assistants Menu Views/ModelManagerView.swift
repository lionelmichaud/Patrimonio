//
//  ModelManagerView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 15/02/2022.
//

import SwiftUI
import Persistence

struct ModelManagerView: View {
    @EnvironmentObject private var dataStore : Store

    var body: some View {
        VStack {
            if dataStore.activeDossier != nil {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.systemGray3))
                    .overlay(Label("iCloud", systemImage: "icloud.fill")
                                .font(.largeTitle))
            }

            HStack {
                if dataStore.activeDossier != nil {
                    HStack {
                        VStack {
                            Button(action: copyFromOpenDossierToCloud,
                                   label: {
                                Image(systemName: "arrow.up")
                                    .font(Font.title.weight(.bold))
                            })
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                                .cornerRadius(.infinity)

                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(Color(UIColor.systemGray2))
                                .overlay(Label("Dossier ouvert", systemImage: "folder.fill")
                                            .font(.largeTitle))

                            Button(action: copyFromTemplateToOpenDossier,
                                   label: {Image(systemName: "arrow.up")
                                    .font(Font.title.weight(.bold))
                            })
                                .padding()
                                .foregroundColor(Color.white)
                                .background(Color.blue)
                                .cornerRadius(.infinity)
                        }

                        Button(action: copyFromOpenDossierToOtherDossiers,
                               label: {
                            Image(systemName: "arrow.right")
                                .font(Font.title.weight(.bold))
                        })
                            .padding()
                            .foregroundColor(Color.white)
                            .background(Color.blue)
                            .cornerRadius(.infinity)
                    }
                }

                VStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color(UIColor.systemGray2))
                        .padding(.top)
                        .overlay(Label(dataStore.activeDossier == nil ? "Dossiers" : "Autres Dossiers",
                                       systemImage: "folder.fill")
                                    .font(.largeTitle))

                    Button(action: copyFromTemplateToOtherDossiers,
                           label: {
                        Image(systemName: "arrow.up")
                            .font(Font.title.weight(.bold))
                    })
                        .padding()
                        .foregroundColor(Color.white)
                        .background(Color.blue)
                        .cornerRadius(.infinity)
                }
            }

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(UIColor.systemGray))
                .overlay(Label("Patron", systemImage: "square.stack.3d.up.fill")
                            .font(.largeTitle))
        }
        .padding()
        .navigationTitle("Gestion des Modèles")
        //.navigationBarTitleDisplayMode(.inline)
    }

    private func copyFromOpenDossierToCloud() {

    }

    private func copyFromTemplateToOpenDossier() {

    }

    private func copyFromTemplateToOtherDossiers() {

    }

    private func copyFromOpenDossierToOtherDossiers() {

    }
}

struct ModelManagerView_Previews: PreviewProvider {
    static var previews: some View {
        ModelManagerView()
    }
}
