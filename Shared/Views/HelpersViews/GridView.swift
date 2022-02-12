//
//  GridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 29/01/2022.
//

import SwiftUI
import AppFoundation
import Persistence
import ModelEnvironment
import FamilyModel

// MARK: - Editeur de Grille Générique

struct GridView<S: Hashable, DisplayView: View, AddView: View, EditView: View> : View {
    let label: String
    @Binding var grid: [S]
    @EnvironmentObject private var dataStore  : Store
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var selection : S?
    @State private var alertItem : AlertItem?
    @State private var showingAddSheet  = false
    @State private var showingEditSheet = false
    @State private var selectedSliceIdx : Int = 0
    private var gridIsValid    : ([S]) -> Bool
    private var initializeGrid : (inout [S]) -> Void
    private var displayView    : (S) -> DisplayView
    private var addView        : (Binding<[S]>) -> AddView
    private var editView       : (Binding<[S]>, Int) -> EditView

    init(label                    : String,
         grid                     : Binding<[S]>,
         gridIsValid              : @escaping ([S]) -> Bool = { _ in true },
         initializeGrid           : @escaping (inout [S]) -> Void,
         @ViewBuilder displayView : @escaping (S) -> DisplayView,
         @ViewBuilder addView     : @escaping (Binding<[S]>) -> AddView,
         @ViewBuilder editView    : @escaping (Binding<[S]>, Int) -> EditView) {
        self.label          = label
        self._grid          = grid
        self.initializeGrid = initializeGrid
        self.gridIsValid    = gridIsValid
        self.displayView    = displayView
        self.addView        = addView
        self.editView       = editView
    }

    var body: some View {
        VStack(alignment: .leading) {
            /// barre d'outils de la Liste
            Button(action : { withAnimation { showingAddSheet = true } },
                   label  : {
                Label("Ajouter une ligne", systemImage: "plus.circle.fill")
            })
                .sheet(isPresented: $showingAddSheet) {
                    addView($grid)
                }
                .padding([.horizontal,.top])

            /// Liste
            List(selection: $selection) {
                ForEach(grid, id: \.self) { slice in
                    displayView(slice)
                        .onTapGesture(count   : 2,
                                      perform : {
                            selectedSliceIdx = grid.firstIndex(of: slice)!
                            showingEditSheet = true
                        })
                        .sheet(isPresented: $showingEditSheet) {
                            editView($grid,
                                     selectedSliceIdx)
                        }
                }
                .onDelete(perform: deleteSlices)
                .onChange(of: grid) { _ in
                    DependencyInjector.updateDependenciesToModel(model: model, family: family, simulation: simulation)
                    model.manageInternalDependencies()
                }
            }
        }
        .alert(item: $alertItem, content: newAlert)
        .navigationTitle(label)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    model     : model,
                    notifyTemplatFolderMissing: {
                        alertItem =
                            AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                      dismissButton : .default(Text("OK")))
                    },
                    notifyFailure: {
                        alertItem =
                            AlertItem(title         : Text("Echec de l'enregistrement"),
                                      dismissButton : .default(Text("OK")))
                    })
            },
            cancelChanges: {
                alertItem = cancelChanges(
                    to         : model,
                    family     : family,
                    simulation : simulation,
                    dataStore  : dataStore)
            },
            isModified: model.isModified)
    }

    private func deleteSlices(at offsets: IndexSet) {
        grid.remove(atOffsets: offsets)
        initializeGrid(&grid)
    }
}

struct GridView_Previews: PreviewProvider {
    static func grid() -> RateGrid {
        [ RateSlice(floor:    0.0, rate: 10.0),
          RateSlice(floor: 1000.0, rate: 20.0),
          RateSlice(floor: 2000.0, rate: 30.0)]
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: GridView(label          : "Nom",
                                                             grid           : .constant(grid()),
                                                             gridIsValid    : { _ in true },
                                                             initializeGrid : { grid in try! grid.initialize() },
                                                             displayView    : { slice in RateSliceView(slice: slice) },
                                                             addView        : { grid in RateSliceAddView(grid: grid) },
                                                             editView       : { grid, idx in RateSliceEditView(grid: grid, idx: idx) })
                                .preferredColorScheme(.dark)
                                .environmentObject(dataStoreTest)
                                .environmentObject(modelTest)
                                .environmentObject(familyTest)
                                .environmentObject(simulationTest))

            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
