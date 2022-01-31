//
//  GridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 29/01/2022.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import FamilyModel

// MARK: - Editeur de Grille Générique

struct GridView<S: Hashable, DisplayView: View, AddView: View, EditView: View> : View {
    let label: String
    @Binding var grid: [S]
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var selection : S?
    @State private var alertItem : AlertItem?
    @State private var showingAddSheet  = false
    @State private var showingEditSheet = false
    @State private var selectedSliceIdx : Int = 0
    private var initializeGrid : (inout [S]) -> Void
    private var displayView    : (S) -> DisplayView
    private var addView        : (Binding<[S]>) -> AddView
    private var editView       : (Binding<[S]>, Int) -> EditView

    init(label                    : String,
         grid                     : Binding<[S]>,
         initializeGrid           : @escaping (inout [S]) -> Void,
         @ViewBuilder displayView : @escaping (S) -> DisplayView,
         @ViewBuilder addView     : @escaping (Binding<[S]>) -> AddView,
         @ViewBuilder editView    : @escaping (Binding<[S]>, Int) -> EditView) {
        self.label          = label
        self._grid          = grid
        self.initializeGrid = initializeGrid
        self.displayView    = displayView
        self.addView        = addView
        self.editView       = editView
    }

    var body: some View {
        /// barre d'outils de la Liste
        VStack(alignment: .leading) {
            Button(action : { withAnimation { showingAddSheet = true } },
                   label  : {
                Label("Ajouter un seuil", systemImage: "plus.circle.fill")
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
                .onChange(of: grid) { _ in viewModel.isModified = true }
            }
        }
        .alert(item: $alertItem, content: newAlert)
        .navigationTitle(label)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(
            applyChangesToTemplate: {
                alertItem = applyChangesToTemplateAlert(
                    viewModel : viewModel,
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
            applyChangesToDossier: {
                alertItem = applyChangesToOpenDossierAlert(
                    viewModel  : viewModel,
                    model      : model,
                    family     : family,
                    simulation : simulation)
            },
            isModified: viewModel.isModified)
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
        let viewModel = DeterministicViewModel(using: modelTest)
        return GridView(label          : "Nom",
                        grid           : .constant(grid()),
                        initializeGrid : { grid in try! grid.initialize() },
                        displayView    : { slice in RateSliceView(slice: slice) },
                        addView        : { grid in RateSliceAddView(grid: grid) },
                        editView       : { grid, idx in RateSliceEditView(grid: grid, idx: idx) })
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 500.0, height: 300.0))
    }
}
