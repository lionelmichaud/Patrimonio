//
//  DossierDetailView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/05/2021.
//

import SwiftUI
import Files
import ModelEnvironment
import LifeExpense
import PersonModel
import DateBoundary
import Persistence
import PatrimoineModel
import FamilyModel
import HelpersView
import SimulationAndVisitors

struct DossierDetailView: View {
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var uiState    : UIState
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var expenses   : LifeExpensesDic
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var simulation : Simulation
    var dossier: Dossier
    @State private var alertItem: AlertItem?
    @State private var showingSheet = false
    
    var activeSection: some View {
        Section {
            if savable {
                Label(
                    title: {
                        Text("Ce dossier est en cours d'utilisation - Modifications non sauvegardées")
                            .foregroundColor(.red)
                            .font(.headline)
                    },
                    icon : {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundColor(.red)
                            .font(.title)
                    })
            } else {
                Label(
                    title: {
                        Text("Ce dossier est en cours d'utilisation")
                            .foregroundColor(.green)
                            .font(.headline)
                    },
                    icon : {
                        Image(systemName: "square.and.arrow.down.on.square")
                            .foregroundColor(.green)
                            .font(.title)
                    })
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            Form {
                /// Section: indicateur de chargement du Dossier
                if dossier.isActive {
                    activeSection
                }
                /// Section: affichage des informations sur le Dossier
                DossierPropertiesView(dossier: dossier,
                                      sectionHeader: "Descriptif du Dossier")
            }
            .textFieldStyle(.roundedBorder)
            .navigationTitle(Text("Dossier"))
            .alert(item: $alertItem, content: newAlert)
            /// Vue modale de modification du dossier
            .sheet(isPresented: $showingSheet) {
                DossierEditView(title        : "Modifier le Dossier",
                                originalItem : dossier)
                    .environmentObject(self.dataStore)
            }
            /// Barre d'outils
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    /// Bouton: Charger
                    Button(
                        action : activate,
                        label  : {
                            Image(systemName: dossier.isActive ? "arrowshape.turn.up.backward" : "square.and.arrow.down.on.square")
                                .imageScale(.large)
                        })
                    .capsuleButtonStyle()
                    .disabled(!activable)

                    /// Bouton: Sauvegarder
                    DiskButton(text: nil) { save(dossier) }
                        .disabled(!savable)

                    /// Bouton: Dupliquer
                    DuplicateButton { duplicate() }

                    /// Bouton: Modifier
                    Button(
                        action : {
                            withAnimation {
                                self.showingSheet = true
                            }
                        },
                        label  : {
                            Image(systemName: "square.and.pencil")
                                .imageScale(.large)
                        })
                    .capsuleButtonStyle()
                    .disabled(!dossier.isActive)
                    
                    /// Bouton: Exporter fichiers du dossier actif
                    Button(action: { share(geometry: geometry) },
                           label: {
                        Image(systemName: "square.and.arrow.up.on.square")
                            .imageScale(.large)
                    })
                    .capsuleButtonStyle()
                    .disabled(!dossier.isActive)
                }
            }
        }
    }

    /// Exporter tous les fichiers contenus dans le dossier actif
    private func share(geometry: GeometryProxy) {
        shareFiles(dataStore: dataStore,
                   alertItem: &alertItem,
                   geometry: geometry)
    }

    /// True si le dossier est inactif ou s'il est actif et à été modifié
    private var activable: Bool {
        !dossier.isActive || savable
    }

    /// True si le dossier est actif et a été modifié
    private var savable: Bool {
        dossier.isActive &&
        (family.isModified ||
         expenses.isModified ||
         patrimoine.isModified ||
         model.isModified ||
         simulation.isModified)
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
                  (family.isModified || expenses.isModified ||
                   patrimoine.isModified || model.isModified ||
                   simulation.isModified) {
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
                try expenses.saveAsJSON(toFolder: folder)
                try patrimoine.saveAsJSON(toFolder: folder)
                try simulation.saveAsJSON(toFolder: folder)
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
            try load(dossier, withIndex: dossierIndex)
        } catch {
            if alertItem == nil {
                self.alertItem = AlertItem(title         : Text((String(describing: error))),
                                           dismissButton : .default(Text("OK")))
            }
            return
        }
    }

    private func load(_ dossier              : Dossier,
                      withIndex dossierIndex : Int) throws {
        var compatibility = false

        try dossier.loadDossierContentAsJSON { folder in
            // Vérifier la compatibilité entre la version de l'app et la version du répertoire `Library/template`.
            do {
                compatibility = try PersistenceManager.checkCompatibilityWithAppVersion(of: folder)

            } catch {
                // la vérification de compatibilité de version s'est mal passée
                let error = DossierError.failedToCheckCompatibility
                self.alertItem = AlertItem(title         : Text("\(error.rawValue) !"),
                                           dismissButton : .default(Text("OK")))
                throw error
            }

            if compatibility {
                // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
                DateBoundary.setPersonEventYearProvider(family)
                // injection de family dans la propriété statique de Expense
                LifeExpense.setMembersCountProvider(family)
                // injection de family dans la propriété statique de Adult
                Adult.setAdultRelativesProvider(family)
                // injection de family dans la propriété statique de Patrimoin
                Patrimoin.familyProvider = family

                do {
                    try model.loadFromJSON(fromFolder: folder)
                    try patrimoine.loadFromJSON(fromFolder: folder)
                    try expenses.loadFromJSON(fromFolder: folder)
                    try family.loadFromJSON(fromFolder: folder,
                                            using     : model)
                    try simulation.loadFromJSON(fromFolder: folder)

                    /// gérer les dépendances entre le Modèle et les objets applicatifs
                    DependencyInjector.updateStaticDependencies(to: model)

                    /// rendre le Dossier actif seulement si tout c'est bien passé
                    dataStore.activate(dossierAtIndex: dossierIndex)

                    /// remettre à zéro la simulation et sa vue
                    simulation.notifyComputationInputsModification()
                    uiState.resetSimulationView()
                } catch {
                    self.alertItem = AlertItem(title         : Text("Echec de chargement du fichier"),
                                               dismissButton : .default(Text("OK")))
                    throw error
                }

            } else {
                // version de dossier incompatible avec version d'Application
                // tenter de rétablir la compatibilité en important seulement les fichier Models de l'Application
                self.alertItem =
                AlertItem(title         : Text("Attention").foregroundColor(.red),
                          message       : Text("Le contenu de ce dossier est incompatible de cette version de l'application. Voulez-vous le mettre à jour. Si vous le mettez à jour, vous perdrai les éventuelles modifications qu'il contient."),
                          primaryButton : .destructive(Text("Mettre à jour"),
                                                       action: {
                    importModelFilesFromApp(toFolder: folder)
                    // injection de family dans la propriété statique de DateBoundary pour lier les évenements à des personnes
                    DateBoundary.setPersonEventYearProvider(family)
                    // injection de family dans la propriété statique de Expense
                    LifeExpense.setMembersCountProvider(family)
                    // injection de family dans la propriété statique de Adult
                    Adult.setAdultRelativesProvider(family)
                    // injection de family dans la propriété statique de Patrimoin
                    Patrimoin.familyProvider = family

                    do {
                        try model.loadFromJSON(fromFolder: folder)
                        try patrimoine.loadFromJSON(fromFolder: folder)
                        try expenses.loadFromJSON(fromFolder: folder)
                        try family.loadFromJSON(fromFolder: folder,
                                                using     : model)
                        try simulation.loadFromJSON(fromFolder: folder)

                        /// gérer les dépendances entre le Modèle et les objets applicatifs
                        DependencyInjector.updateStaticDependencies(to: model)

                        /// rendre le Dossier actif seulement si tout c'est bien passé
                        dataStore.activate(dossierAtIndex: dossierIndex)

                        /// remettre à zéro la simulation et sa vue
                        simulation.notifyComputationInputsModification()
                        uiState.resetSimulationView()
                    } catch {
                        DispatchQueue.main.async {
                            self.alertItem = AlertItem(title         : Text("Echec de la mise à jour"),
                                                       dismissButton : .default(Text("OK")))
                        }
                    }
                }),
                          secondaryButton: .cancel())
            }
        }
    }

    private func importModelFilesFromApp(toFolder: Folder) {
        do {
            try PersistenceManager.duplicateFilesFromApp(toFolder: toFolder) { fromFolder, toFolder in
                try model.loadFromJSON(fromFolder: fromFolder)
                try model.saveAsJSON(toFolder: toFolder)
            }
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la mise à jour"),
                                       dismissButton : .default(Text("OK")))
        }
    }

    /// Dupliquer le Dossier sélectionné
    private func duplicate() {
        guard !savable else {
            self.alertItem = AlertItem(title         : Text("Attention"),
                                       message       : Text("Toutes les modifications sur le dossier ouvert seront perdues"),
                                       primaryButton : .default(Text("Continuer"),
                                                                action: {
                                                                    do {
                                                                        try dataStore.duplicate(dossier)
                                                                    } catch {
                                                                        DispatchQueue.main.async {
                                                                            self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier !"),
                                                                                                       dismissButton : .default(Text("OK")))
                                                                        }
                                                                    }
                                                                }),
                                       secondaryButton: .cancel())
            return
        }
        
        do {
            try dataStore.duplicate(dossier)
        } catch {
            self.alertItem = AlertItem(title         : Text("Echec de la duplication du dossier !"),
                                       dismissButton : .default(Text("OK")))
        }
    }
}

struct DossierDetailView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        let dossier = TestEnvir.dataStore.dossiers[0]
        return NavigationView {
            List {
                NavigationLink(destination : DossierDetailView(dossier: dossier)
                                .environmentObject(TestEnvir.dataStore)
                                .environmentObject(TestEnvir.model)
                                .environmentObject(TestEnvir.uiState)
                                .environmentObject(TestEnvir.family)
                                .environmentObject(TestEnvir.expenses)
                                .environmentObject(TestEnvir.patrimoine)
                                .environmentObject(TestEnvir.simulation)
                ) {
                    Text("DossierDetailView")
                }
                .isDetailLink(true)
            }
        }
    }
}
