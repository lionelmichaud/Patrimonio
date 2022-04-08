//
//  RateGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

// MARK: - Editeur de Barême [seuil €, taux %]

typealias RateGridView = GridView<RateSlice,
                                    RateSliceView,
                                    RateSliceAddView,
                                    RateSliceEditView>
extension RateGridView {
    init(label : String,
         grid  : Transac<[RateSlice]>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = RateGridView(label          : label,
                            grid           : grid,
                            initializeGrid : { grid in try! grid.initialize() },
                            displayView    : { slice in RateSliceView(slice: slice) },
                            addView        : { grid in RateSliceAddView(grid: grid) },
                            editView       : { grid, idx in RateSliceEditView(grid: grid, idx: idx) },
                            updateDependenciesToModel : updateDependenciesToModel)
    }
}

// MARK: - Display a RateSlice [seuil €, taux %]

struct RateSliceView: View {
    var slice: RateSlice
    
    var body: some View {
        HStack {
            AmountView(label   : "Seuil",
                       amount  : slice.floor)
            Spacer(minLength: 50)
            PercentNormView(label   : "Taux",
                            percent : slice.rate)
        }
    }
}

// MARK: - Edit a RateSlice of the Grid [seuil €, taux %]

struct RateSliceEditView: View {
    @Transac private var grid: RateGrid
    private var idx: Int
    @Environment(\.dismiss) private var dismiss
    @State private var modifiedSlice : RateSlice
    @State private var alertItem     : AlertItem?
    
    init(grid : Transac<RateGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue : grid[idx].wrappedValue)
    }
    
    private var toolBar: some View {
        HStack {
            Button("Annuler") {
                dismiss()
            }.buttonStyle(.bordered)
            Spacer()
            Text("Modifier").font(.title).fontWeight(.bold)
            Spacer()
            Button("OK", action : updateSlice)
                .buttonStyle(.bordered)
                .disabled(!formIsValid())
                .alert(item: $alertItem, content: newAlert)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    var body: some View {
        VStack {
            /// Barre de titre et boutons
            toolBar
            /// Formulaire
            Form {
                VStack {
                    AmountEditView(label  : "Seuil",
                                   amount : $modifiedSlice.floor)
                    PercentNormEditView(label   : "Taux",
                                        percent : $modifiedSlice.rate)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.floor >= 0
    }
    
    private func updateSlice() {
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.floor < $1.floor })
        //try! grid.initialize()
        
        dismiss()
    }
}

// MARK: - Add a RateSlice to the Grid [seuil €, taux %]

struct RateSliceAddView: View {
    @Transac var grid: RateGrid
    @Environment(\.dismiss) private var dismiss
    @State private var newSlice = RateSlice(floor: 0, rate: 0)
    @State private var alertItem : AlertItem?
    
    private var toolBar: some View {
        HStack {
            Button("Annuler") {
                dismiss()
            }.buttonStyle(.bordered)
            Spacer()
            Text("Ajouter...").font(.title).fontWeight(.bold)
            Spacer()
            Button("OK", action: addSlice)
                .buttonStyle(.bordered)
                .disabled(!formIsValid())
                .alert(item: $alertItem, content: newAlert)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    var body: some View {
        VStack {
            /// Barre de titre et boutons
            toolBar
            /// Formulaire
            Form {
                VStack {
                    AmountEditView(label   : "Seuil",
                                   amount  : $newSlice.floor)
                    PercentNormEditView(label   : "Taux",
                                        percent : $newSlice.rate)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        newSlice.floor >= 0
    }
    
    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.floor != newSlice.floor }) else {
            self.alertItem = AlertItem(title         : Text("Le seuil existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        
        grid.append(newSlice)
        grid.sort(by: { $0.floor < $1.floor })
        //try! grid.initialize()
        
        dismiss()
    }
}

// MARK: - Previews

struct RateSliceView_Previews: PreviewProvider {
    static var previews: some View {
        RateSliceView(slice: RateSlice(floor: 1000.0,
                                       rate: 10.0))
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
    }
}

struct RateGridView_Previews: PreviewProvider {
    static func grid() -> RateGrid {
        [ RateSlice(floor:    0.0, rate: 10.0),
          RateSlice(floor: 1000.0, rate: 20.0),
          RateSlice(floor: 2000.0, rate: 30.0)]
    }
    
    static var previews: some View {
            NavigationView {
                NavigationLink("Test", destination: RateGridView(label: "Nom",
                                                                 grid : .init(source: grid()),
                                                                 updateDependenciesToModel: { }))
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
