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
                        Text("Dossier en cours d'utilisation - Modifications non sauvegardées")
                            .foregroundColor(.red)
                            .font(.headline)
                    },
                    icon : {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.red)
                            .font(.title)
                    })
            } else {
                Label(
                    title: {
                        Text("Dossier en cours d'utilisation")
                            .foregroundColor(.green)
                            .font(.headline)
                    },
                    icon : {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundColor(.green)
                            .font(.title)
                    })
            }
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
        .alert(item: $alertItem, content: createAlert)
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
                DiskButton { save(dossier) }
                    .disabled(!savable)
            }
            /// Bouton: Dupliquer
            ToolbarItem(placement: .automatic) {
                DuplicateButton { duplicate() }
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
                    DependencyInjector.manageDependencies(to: model)
                    
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
                // tenter de rétablir la compatibilité en important les fichier Models de l'Application
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
                                                                DependencyInjector.manageDependencies(to: model)
                                                                
                                                                /// rendre le Dossier actif seulement si tout c'est bien passé
                                                                dataStore.activate(dossierAtIndex: dossierIndex)
                                                                
                                                                /// remettre à zéro la simulation et sa vue
                                                                simulation.notifyComputationInputsModification()
                                                                uiState.resetSimulationView()
                                                            } catch {
                                                                self.alertItem = AlertItem(title         : Text("Echec de la mise à jour"),
                                                                                           dismissButton : .default(Text("OK")))
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
        loadTestFilesFromBundle()
        let dossier = dataStoreTest.dossiers[0]
        return NavigationView {
            List {
                NavigationLink(destination : DossierDetailView(dossier: dossier)
                                .environmentObject(dataStoreTest)
                                .environmentObject(modelTest)
                                .environmentObject(uiStateTest)
                                .environmentObject(familyTest)
                                .environmentObject(expensesTest)
                                .environmentObject(patrimoineTest)
                                .environmentObject(simulationTest)
                ) {
                    Text("DossierDetailView")
                }
                .isDetailLink(true)
            }
        }
    }
}
