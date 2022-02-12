//
//  RateGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Editeur de Barême [seuil €, taux %]

typealias RateGridView = GridView<RateSlice, RateSliceView, RateSliceAddView, RateSliceEditView>
extension RateGridView {
    init(label : String,
         grid  : Binding<[RateSlice]>) {
        self = RateGridView(label          : label,
                            grid           : grid,
                            initializeGrid : { grid in try! grid.initialize() },
                            displayView    : { slice in RateSliceView(slice: slice) },
                            addView        : { grid in RateSliceAddView(grid: grid) },
                            editView       : { grid, idx in RateSliceEditView(grid: grid, idx: idx) })
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
            PercentView(label   : "Taux",
                        percent : slice.rate)
        }
    }
}

// MARK: - Edit a RateSlice of the Grid [seuil €, taux %]

struct RateSliceEditView: View {
    @Binding private var grid: RateGrid
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : RateSlice
    @State private var alertItem     : AlertItem?
    
    init(grid : Binding<RateGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue : RateSlice(floor : grid[idx].wrappedValue.floor,
                                                        rate  : grid[idx].wrappedValue.rate * 100.0))
    }
    
    private var toolBar: some View {
        HStack {
            Button(action : { self.presentationMode.wrappedValue.dismiss() },
                   label  : { Text("Annuler") })
                .capsuleButtonStyle()
            Spacer()
            Text("Modifier").font(.title).fontWeight(.bold)
            Spacer()
            Button(action : updateSlice,
                   label  : { Text("OK") })
                .capsuleButtonStyle()
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
                    PercentEditView(label   : "Taux",
                                    percent : $modifiedSlice.rate)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.floor >= 0
    }
    
    private func updateSlice() {
        modifiedSlice.rate /= 100.0 // [0, 100%] => [0, 1.0]
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.floor < $1.floor })
        try! grid.initialize()
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a RateSlice to the Grid [seuil €, taux %]

struct RateSliceAddView: View {
    @Binding var grid: RateGrid
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = RateSlice(floor: 0, rate: 10)
    @State private var alertItem : AlertItem?
    
    private var toolBar: some View {
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() },
                   label: { Text("Annuler") })
                .capsuleButtonStyle()
            Spacer()
            Text("Ajouter...").font(.title).fontWeight(.bold)
            Spacer()
            Button(action: addSlice,
                   label: { Text("OK") })
                .capsuleButtonStyle()
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
                    PercentEditView(label   : "Taux",
                                    percent : $newSlice.rate)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
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
        
        newSlice.rate /= 100.0 // [0, 100%] => [0, 1.0]
        grid.append(newSlice)
        grid.sort(by: { $0.floor < $1.floor })
        try! grid.initialize()
        
        self.presentationMode.wrappedValue.dismiss()
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
        loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: RateGridView(label: "Nom",
                                                                 grid: .constant(grid()))
                                .environmentObject(dataStoreTest)
                                .environmentObject(modelTest)
                                .environmentObject(familyTest)
                                .environmentObject(simulationTest))
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
