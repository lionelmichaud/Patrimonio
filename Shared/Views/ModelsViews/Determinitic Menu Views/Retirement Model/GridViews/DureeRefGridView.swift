//
//  DureeRefGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import RetirementModel
import HelpersView

typealias SliceRegimeLegal = RegimeGeneral.SliceRegimeLegal
typealias GridRegimeLegal = [SliceRegimeLegal]

// MARK: - Editeur de GridRegimeLegal [année naissance, nb trimestre, age taux plein]

typealias DureeRefGridView = GridView<SliceRegimeLegal,
                                      DureeRefSliceView,
                                      DureeRefSliceAddView,
                                      DureeRefSliceEditView>
extension DureeRefGridView {
    init(label : String,
         grid  : Binding<[SliceRegimeLegal]>) {
        self = DureeRefGridView(label          : label,
                                grid           : grid,
                                initializeGrid : { _ in },
                                displayView    : { slice in DureeRefSliceView(slice: slice) },
                                addView        : { grid in DureeRefSliceAddView(grid: grid) },
                                editView       : { grid, idx in DureeRefSliceEditView(grid: grid, idx: idx) })
    }
}

// MARK: - Display a SliceRegimeLegal [année naissance, nb trimestre, age taux plein]

struct DureeRefSliceView: View {
    var slice: SliceRegimeLegal

    var body: some View {
        VStack {
            IntegerView(label   : "Année de naissance",
                        integer : slice.birthYear,
                        weight  : .bold)
            IntegerView(label   : "Nb trimestre",
                        integer : slice.ndTrimestre)
            IntegerView(label   : "Age taux plein",
                        integer : slice.ageTauxPlein)
        }
    }
}

// MARK: - Edit a SliceRegimeLegal of the Grid [année naissance, nb trimestre, age taux plein]

struct DureeRefSliceEditView: View {
    @Binding private var grid: GridRegimeLegal
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : SliceRegimeLegal
    @State private var alertItem     : AlertItem?

    init(grid : Binding<GridRegimeLegal>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue: grid[idx].wrappedValue)
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
                    IntegerEditView(label   : "Année de naissance",
                                    integer : $modifiedSlice.birthYear)
                    //Spacer(minLength: 50)
                    IntegerEditView(label   : "Nb trimestre",
                                    integer : $modifiedSlice.ndTrimestre)
                    //Spacer(minLength: 50)
                    IntegerEditView(label   : "Age taux plein",
                                    integer : $modifiedSlice.ageTauxPlein)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.birthYear >= 0
    }

    private func updateSlice() {
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.birthYear < $1.birthYear })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année naissance, nb trimestre, age taux plein]

struct DureeRefSliceAddView: View {
    @Binding var grid: GridRegimeLegal
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = SliceRegimeLegal(birthYear    : 0,
                                                   ndTrimestre  : 0,
                                                   ageTauxPlein : 0)
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
                    IntegerEditView(label   : "Année de naissance",
                                    integer : $newSlice.birthYear)
                    //Spacer(minLength: 50)
                    IntegerEditView(label   : "Nb trimestre",
                                    integer : $newSlice.ndTrimestre)
                    //Spacer(minLength: 50)
                    IntegerEditView(label   : "Age taux plein",
                                    integer : $newSlice.ageTauxPlein)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        newSlice.birthYear >= 0
    }

    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.birthYear != newSlice.birthYear }) else {
            self.alertItem = AlertItem(title         : Text("Le seuil existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        grid.append(newSlice)
        grid.sort(by: { $0.birthYear < $1.birthYear })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

struct DureeRefGridView_Previews: PreviewProvider {
    static func grid() -> GridRegimeLegal {
        [ SliceRegimeLegal(birthYear    : 1964,
                           ndTrimestre  : 100,
                           ageTauxPlein : 62),
          SliceRegimeLegal(birthYear    : 1965,
                           ndTrimestre  : 102,
                           ageTauxPlein : 64),
          SliceRegimeLegal(birthYear    : 1966,
                           ndTrimestre  : 104,
                           ageTauxPlein : 65)]
    }

    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
            NavigationLink("Test", destination: DureeRefGridView(label: "Nom",
                                                                 grid : .constant(grid()))
                            .environmentObject(TestEnvir.dataStore)
                            .environmentObject(TestEnvir.model)
                            .environmentObject(TestEnvir.family)
                            .environmentObject(TestEnvir.simulation))
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
