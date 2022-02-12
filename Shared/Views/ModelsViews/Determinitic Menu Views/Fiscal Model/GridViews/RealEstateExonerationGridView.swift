//
//  RealEstateExonerationGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 29/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel

// MARK: - Editeur de ExonerationSlice [année, discount %, sum %]

typealias RealEstateExonerationGridView = GridView<ExonerationSlice,
                                                   RealEstateExonerationSliceView,
                                                   RealEstateExonerationSliceAddView,
                                                   RealEstateExonerationSliceEditView>
extension RealEstateExonerationGridView {
    init(label : String,
         grid  : Binding<[ExonerationSlice]>) {
        self = RealEstateExonerationGridView(label          : label,
                                             grid           : grid,
                                             initializeGrid : { _ in },
                                             displayView    : { slice in RealEstateExonerationSliceView(slice: slice) },
                                             addView        : { grid in RealEstateExonerationSliceAddView(grid: grid) },
                                             editView       : { grid, idx in RealEstateExonerationSliceEditView(grid: grid, idx: idx) })
    }
}

// MARK: - Display a ExonerationSlice [année, discount %, sum %]

struct RealEstateExonerationSliceView: View {
    var slice: ExonerationSlice

    var body: some View {
        VStack {
            IntegerView(label   : "A partir de",
                        integer : slice.floor,
                        weight  : .bold,
                        comment : "ans")
            PercentView(label   : "Décote",
                        percent : slice.discountRate / 100.0,
                        comment : "par année de détention au-delà")
            PercentView(label   : "Décote cumulée",
                        percent : slice.prevDiscount / 100.0,
                        comment : "cumul des tranches précédentes")
        }
    }
}

// MARK: - Edit a ExonerationSlice of the Grid [année, discount %, sum %]

struct RealEstateExonerationSliceEditView: View {
    @Binding private var grid: ExonerationGrid
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : ExonerationSlice
    @State private var alertItem     : AlertItem?

    init(grid : Binding<ExonerationGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(
            initialValue : ExonerationSlice(floor        : grid[idx].wrappedValue.floor,
                                            discountRate : grid[idx].wrappedValue.discountRate,
                                            prevDiscount : grid[idx].wrappedValue.prevDiscount))
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
                    IntegerEditView(label   : "A partir de",
                                    comment : "ans",
                                    integer : $modifiedSlice.floor)
                    //Spacer(minLength: 50)
                    PercentEditView(label   : "Décote",
                                    percent : $modifiedSlice.discountRate)
                    //Spacer(minLength: 50)
                    PercentEditView(label   : "Décote cumulée",
                                    percent : $modifiedSlice.prevDiscount)
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
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.floor < $1.floor })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année, discount %, sum %]

struct RealEstateExonerationSliceAddView: View {
    @Binding var grid: ExonerationGrid
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = ExonerationSlice(floor        : 0,
                                                   discountRate : 0,
                                                   prevDiscount : 0)
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
                    IntegerEditView(label   : "A partir de",
                                    comment : "ans",
                                    integer : $newSlice.floor)
                    PercentEditView(label   : "Décote",
                                    percent : $newSlice.discountRate)
                    PercentEditView(label   : "Décote cumulée",
                                    percent : $newSlice.prevDiscount)
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

        grid.append(newSlice)
        grid.sort(by: { $0.floor < $1.floor })

        self.presentationMode.wrappedValue.dismiss()
    }
}

struct RealEstateExonerationGridView_Previews: PreviewProvider {
    static func grid() -> ExonerationGrid {
        [ ExonerationSlice(floor        : 5,
                           discountRate : 0.01,
                           prevDiscount : 0),
          ExonerationSlice(floor        : 10,
                           discountRate : 0.02,
                           prevDiscount : 0.05),
          ExonerationSlice(floor        : 15,
                           discountRate : 0.04,
                           prevDiscount : 0.15)]
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: RealEstateExonerationGridView(label: "Nom",
                                                                                  grid : .constant(grid()))
                                .environmentObject(dataStoreTest)
                                .environmentObject(modelTest)
                                .environmentObject(familyTest)
                                .environmentObject(simulationTest))
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
