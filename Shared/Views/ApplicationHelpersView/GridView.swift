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
import HelpersView
import SimulationAndVisitors

// MARK: - Editeur de Grille Générique

/// Editeur de Grille Générique
/// - Parameters:
///   - label: Nom de la grille
///   - grid: Grille à éditer
///   - gridIsValid: closure qui doit retourner Vrai si la grille est valide
///   - initializeGrid: closure qui initialize la grille (si nécessaire) à chaque foi qu'elle change
///   - displayView: View présentant une ligne de la grille
///   - addView: View permettant d'ajouter une ligne de la grille
///   - editView: View permettant de modifier une ligne de la grille
///   - updateDependenciesToModel: Closure qui met à jour toutes les dépendances vis-à-vis de S
struct GridView<S: Hashable, DisplayView: View, AddView: View, EditView: View> : View {
    /// Nom de la grille
    let label: String
    /// Grille à éditer
    @Transac var grid: [S]
    /// Closure qui doit retourner Vrai si la grille est valide
    private var gridIsValid    : ([S]) -> Bool
    /// Closure qui initialize la grille (si nécessaire) à chaque foi qu'elle change
    private var initializeGrid : (inout [S]) -> Void
    /// View présentant une ligne de la grille
    private var displayView    : (S) -> DisplayView
    /// View permettant d'ajouter une ligne de la grille
    private var addView        : (Transac<[S]>) -> AddView
    /// View permettant de modifier une ligne de la grille
    private var editView       : (Transac<[S]>, Int) -> EditView
    /// Closure qui met à jour toutes les dépendances vis-à-vis de S
    let updateDependenciesToModel: ( ) -> Void
    @State private var selection : S?
    @State private var alertItem : AlertItem?
    @State private var showingAddSheet  = false
    @State private var showingEditSheet = false
    @State private var selectedSliceIdx : Int = 0

    /// Création
    /// - Parameters:
    ///   - label: Nom de la grille
    ///   - grid: Grille à éditer
    ///   - gridIsValid: closure qui doit retourner Vrai si la grille est valide
    ///   - initializeGrid: closure qui initialize la grille (si nécessaire) à chaque foi qu'elle change
    ///   - displayView: View présentant une ligne de la grille
    ///   - addView: View permettant d'ajouter une ligne de la grille
    ///   - editView: View permettant de modifier une ligne de la grille
    ///   - updateDependenciesToModel: Closure qui met à jour toutes les dépendances vis-à-vis de S
    init(label                    : String,
         grid                     : Transac<[S]>,
         gridIsValid              : @escaping ([S]) -> Bool = { _ in true },
         initializeGrid           : @escaping (inout [S]) -> Void = { _ in },
         @ViewBuilder displayView : @escaping (S) -> DisplayView,
         @ViewBuilder addView     : @escaping (Transac<[S]>) -> AddView,
         @ViewBuilder editView    : @escaping (Transac<[S]>, Int) -> EditView,
         updateDependenciesToModel: @escaping ( ) -> Void) {
        self.label          = label
        self._grid          = grid
        self.initializeGrid = initializeGrid
        self.gridIsValid    = gridIsValid
        self.displayView    = displayView
        self.addView        = addView
        self.editView       = editView
        self.updateDependenciesToModel = updateDependenciesToModel
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
            .padding()

            Text("Double cliquer sur une ligne pour la modifier.")
                .foregroundColor(.secondary)
                .padding(.horizontal)

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
            }
            Spacer()
        }
        .alert(item: $alertItem, content: newAlert)
        .navigationTitle(label)
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $grid,
                              isValid                   : gridIsValid(grid),
                              updateDependenciesToModel : onChange)
    }

    private func onChange() {
        initializeGrid(&grid)
        updateDependenciesToModel()
    }

    private func deleteSlices(at offsets: IndexSet) {
        var copy = grid
        copy.remove(atOffsets: offsets)
        initializeGrid(&copy)
        grid = copy
    }
}

struct GridView_Previews: PreviewProvider {
    static func grid() -> RateGrid {
        [ RateSlice(floor:    0.0, rate: 10.0),
          RateSlice(floor: 1000.0, rate: 20.0),
          RateSlice(floor: 2000.0, rate: 30.0)]
    }

    static var previews: some View {
        NavigationView {
            EmptyView()
            GridView(label          : "label",
                     grid           : .init(source: grid()), // .constant(grid()),
                     gridIsValid    : { _ in true },
                     initializeGrid : { grid in try! grid.initialize() },
                     displayView    : { slice in RateSliceView(slice: slice) },
                     addView        : { grid in RateSliceAddView(grid: grid) },
                     editView       : { grid, idx in RateSliceEditView(grid: grid, idx: idx) },
                     updateDependenciesToModel: { })
            .preferredColorScheme(.dark)
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
