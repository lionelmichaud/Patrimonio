//
//  DossierDetailView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import SwiftUI
import FiscalModel
import ModelEnvironment
import Persistence

struct DossierDetailView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    var dossier: Dossier
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false
    
    var activeSection: some View {
        Section {
            Label(
                title: {
                    Text("Dossier en cours d'utilisation")
                        .font(.headline)
                },
                icon : {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundColor(.red)
                        .font(.title)
                })
        }
    }
    
    var body: some View {
        Form {
            // indicateur de chargement du Dossier
            if dossier.isActive {
                activeSection
            }
            // affichage du Dossier
            DossierPropertiesView(dossier: dossier,
                                  sectionHeader: "Descriptif du Dossier")
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .navigationTitle(Text("Dossier"))
        .alert(item: $alertItem, content: myAlert)
        .sheet(isPresented: $showingSheet) {
            DossierEditView(title        : "Modifier le Dossier",
                            originalItem : dossier)
                .environmentObject(self.dataStore)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                /// Bouton: Charger
                Button(
                    action : activate,
                    label  : {
                        HStack {
                            if dossier.isActive {
                                Image(systemName: "arrowshape.turn.up.backward")
                                    .imageScale(.large)
                                Text("Revenir")

                            } else {
                                Image(systemName: "square.and.arrow.down")
                                    .imageScale(.large)
                                Text("Charger")

                            }
                        }
                    })
                    .capsuleButtonStyle()
                    .disabled(!activable)
            }
            /// Bouton: Sauvegarder
            ToolbarItem(placement: .automatic) {
                SaveToDiskButton { save(dossier) }
                    .disabled(!savable)
            }
            /// Bouton: Dupliquer
            ToolbarItem(placement: .automatic) {
                Button(
                    action : duplicate,
                    label  : {
                        HStack {
                            Image(systemName: "doc.on.doc.fill")
                                .imageScale(.medium)
                            Text("Dupliquer")
                        }
                    })
                    .capsuleButtonStyle()
            }
            /// Bouton: Modifier
            ToolbarItem(placement: .automatic) {
                Button(
                    action : {
                        withAnimation {
                            self.showingSheet = true
                        }
                    },
                    label  : {
                        HStack {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                            Text("Modifier")
                        }
                    })
                    .capsuleButtonStyle()
                    .disabled(!dossier.isActive)
            }
       }
    }

    /// True si le dossier est inactif ou s'il est actif et à été modifié
    private var activable: Bool {
        !dossier.isActive || savable
    }
    
    /// True si le dossier est actif et a été modifié
    private var savable: Bool {
        dossier.isActive &&
            (family.isModified || patrimoine.isModified || model.isModified)
    }
    
    /// si le dossier est déjà actif et a été modifié alors prévenir que les modif vont être écrasées
    private func activate() {
        if savable {
            // le dossier sélectionné est déjà chargé avec des modifications non sauvegardées
            self.alertItem = AlertItem(title         : Text("Attention").foregroundColor(.red),
                                       message       : Text("Toutes les modifications seront perdues"),
                                       primaryButton : .destructive(Text("Revenir"),
                                                                    action: load),
                                       secondaryButton: .cancel())
        } else if let activeDossier = dataStore.activeDossier,
                  activeDossier != dossier,
                  (family.isModified || patrimoine.isModified || model.isModified) {
            // le dossier sélectionné n'est pas encore chargé
            // et il y a déjà un autre dossier chargé avec des modifications non sauvegardées
            self.alertItem = AlertItem(title         : Text("Attention").foregroundColor(.red),
                                       message       : Text("Toutes les modifications sur le dossier ouvert seront perdues"),
                                       primaryButton : .destructive(Text("Charger"),
                                                                    action: load),
                                       secondaryButton: .cancel())
        } else {
            load()
        }
    }

    // MARK: - Methods
    
    /// Enregistrer les données utilisateur dans le Dossier sélectionné actif
    private func save(_ dossier: Dossier) {
        do {
            try dossier.saveDossierContentAsJSON { folder in
                try model.saveAsJSON(toFolder: folder)
                try family.saveAsJSON(toFolder: folder)
                try patrimoine.saveAsJSON(toFolder: folder)
                // forcer la vue à se rafraichir
                dataStore.objectWillChange.send()
                Simulation.playSound()
            }
        } catch {
            self.alertItem = AlertItem(title         : Text((error as! DossierError).rawValue),
                                       dismissButton : .default(Text("OK")))
        }
    }

    /// Rendre le Dossier sélectionné actif et charger ses données dans le modèle
    private func load() {
        guard let dossierIndex = dataStore.dossiers.firstIndex(of: dossier) else {
            self.alertItem = AlertItem(title         : Text("Impossible de trouver le Dossier !"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        /// charger les fichiers JSON
        do {
            try dossier.loadDossierContentAsJSON { folder in
                try model.loadFromJSON(fromFolder: folder)
                try patrimoine.loadFromJSON(fromFolder: folder)
                try family.loadFromJSON(fromFolder: folder,
                                        using     : model)
            }
        } catch {
            self.alertItem = AlertItem(title         : Text((error as! DossierError).rawValue),
                                       dismissButton : .default(Text("OK")))
        }
        
        /// gérer les dépendances entre le Modèle et les objets applicatifs
        DependencyInjector.manageDependencies(to: model)
        
        /// rendre le Dossier actif seulement si tout c'est bien passé
        dataStore.activate(dossierAtIndex: dossierIndex)
        
        /// remettre à zéro la simulation et sa vue
        simulation.reset()
        uiState.reset()
    }

    /// Dupliquer le Dossier sélectionné
    private func duplicate() {
        do {
            try dataStore.duplicate(dossier)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct DossierDetailView_Previews: PreviewProvider {
    static var dataStore  = Store()
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static let dossier = Dossier()
        .namedAs("Nom du dossier")
        .annotatedBy("note ligne 1\nligne 2")
        .createdOn(Date.now)
        .activated()
    
    static var previews: some View {
        NavigationView {
            List {
                NavigationLink(destination : DossierDetailView(dossier: dossier)
                    .previewLayout(.sizeThatFits)
                    .environmentObject(dataStore)
                    .environmentObject(model)
                    .environmentObject(uiState)
                    .environmentObject(family)
                    .environmentObject(patrimoine)
                    .environmentObject(simulation)
                ) {
                    Text("DossierDetailView")
                }
                .isDetailLink(true)
            }
        }
    }
}
