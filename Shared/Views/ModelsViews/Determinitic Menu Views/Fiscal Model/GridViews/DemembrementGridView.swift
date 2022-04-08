//
//  DemembrementGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 31/01/2022.
//

import SwiftUI
import AppFoundation
import FiscalModel
import HelpersView

// MARK: - Editeur de Demembrement [age, usuFruit %, nueProp %]

typealias DemembrementGridView = GridView<DemembrementSlice,
                                          DemembrementSliceView,
                                          DemembrementSliceAddView,
                                          DemembrementSliceEditView>
extension DemembrementGridView {
    init(label : String,
         grid  : Transac<[DemembrementSlice]>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = DemembrementGridView(label          : label,
                                    grid           : grid,
                                    displayView    : { slice in DemembrementSliceView(slice: slice) },
                                    addView        : { grid in DemembrementSliceAddView(grid: grid) },
                                    editView       : { grid, idx in DemembrementSliceEditView(grid: grid, idx: idx) },
                                    updateDependenciesToModel : updateDependenciesToModel)
    }
}

// MARK: - Display a Demembrement [age, usuFruit %, nueProp %]

struct DemembrementSliceView: View {
    var slice: DemembrementSlice

    var body: some View {
        HStack {
            IntegerView(label   : "A partir de",
                        integer : slice.floor,
                        comment : "ans")
            Divider()
            Spacer(minLength: 125)
            PercentNormView(label   : "Usufruit",
                            percent : slice.usuFruit)
            Divider()
            Spacer(minLength: 125)
            PercentNormView(label   : "Nue propriété",
                            percent : slice.nueProp)
        }
    }
}

// MARK: - Edit a Demembrement [age, usuFruit %]

struct DemembrementSliceEditView: View {
    @Transac private var grid: DemembrementGrid
    private var idx: Int
    @Environment(\.dismiss) private var dismiss
    @State private var modifiedSlice : DemembrementSlice
    @State private var alertItem     : AlertItem?

    init(grid : Transac<DemembrementGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue: grid[idx].wrappedValue)
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
                HStack {
                    IntegerEditView(label    : "A partir de",
                                    comment  : "ans",
                                    integer  : $modifiedSlice.floor,
                                    validity : .poz)
                    Spacer(minLength: 50)
                    PercentNormEditView(label   : "Usufruit",
                                        percent : $modifiedSlice.usuFruit)
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

        dismiss()
    }
}

// MARK: - Add a Demembrement [age, usuFruit %]

struct DemembrementSliceAddView: View {
    @Transac var grid: DemembrementGrid
    @Environment(\.dismiss) private var dismiss
    @State private var newSlice = DemembrementSlice(floor    : 0,
                                                    usuFruit : 0)
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
                    IntegerEditView(label    : "A partir de",
                                    comment  : "ans",
                                    integer  : $newSlice.floor,
                                    validity : .poz)
                    PercentNormEditView(label   : "Usufruit",
                                        percent : $newSlice.usuFruit)
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

        dismiss()
    }
}

struct DemembrementGridView_Previews: PreviewProvider {
    static func grid() -> DemembrementGrid {
        [ DemembrementSlice(floor    : 5,
                            usuFruit : 0.1),
          DemembrementSlice(floor    : 10,
                            usuFruit : 0.2),
          DemembrementSlice(floor    : 15,
                            usuFruit : 0.4)]
    }

    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            NavigationLink("Test", destination: DemembrementGridView(label: "Nom",
                                                                     grid : .init(source: grid()),
                                                                     updateDependenciesToModel: { }))
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: 1000.0, height: 400.0))
        }
    }
}
