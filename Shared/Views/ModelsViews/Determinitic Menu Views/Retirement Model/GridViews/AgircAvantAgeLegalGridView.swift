//
//  AgircAvantAgeLegalGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import AppFoundation
import RetirementModel
import HelpersView

typealias SliceAgircAvantAgeLegal = RegimeAgirc.SliceAvantAgeLegal
typealias GridAgircAvantAgeLegal = [SliceAgircAvantAgeLegal]

typealias AgircAvantAgeLegalGridView = GridView<SliceAgircAvantAgeLegal,
                                                AgircAvantAgeLegalSliceView,
                                                AgircAvantAgeLegalSliceAddView,
                                                AgircAvantAgeLegalSliceEditView>
extension AgircAvantAgeLegalGridView {
    init(label : String,
         grid  : Transac<[SliceAgircAvantAgeLegal]>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = AgircAvantAgeLegalGridView(label          : label,
                                          grid           : grid,
                                          displayView    : { slice in AgircAvantAgeLegalSliceView(slice: slice) },
                                          addView        : { grid in AgircAvantAgeLegalSliceAddView(grid: grid) },
                                          editView       : { grid, idx in AgircAvantAgeLegalSliceEditView(grid: grid, idx: idx) },
                                          updateDependenciesToModel : updateDependenciesToModel)
    }
}

// MARK: - Display a SliceAgircAvantAgeLegal [année naissance, nb trimestre, age taux plein]

struct AgircAvantAgeLegalSliceView: View {
    var slice: SliceAgircAvantAgeLegal

    var body: some View {
        VStack {
            IntegerView(label   : "Nombre de trimestres jusqu'à l'âge légal de départ à la retraite",
                        integer : slice.ndTrimAvantAgeLegal)
            PercentNormView(label   : "Coefficient de réduction",
                            percent : slice.coef)
        }
    }
}

// MARK: - Edit a SliceAgircAvantAgeLegal of the Grid [année naissance, nb trimestre, age taux plein]

struct AgircAvantAgeLegalSliceEditView: View {
    @Transac private var grid: GridAgircAvantAgeLegal
    private var idx: Int
    @Environment(\.dismiss) private var dismiss
    @State private var modifiedSlice : SliceAgircAvantAgeLegal
    @State private var alertItem     : AlertItem?

    init(grid : Transac<GridAgircAvantAgeLegal>,
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
                VStack {
                    IntegerEditView(label    : "Nombre de trimestres jusqu'à l'âge légal de départ à la retraite",
                                    integer  : $modifiedSlice.ndTrimAvantAgeLegal,
                                    validity : .poz)
                    PercentNormEditView(label   : "Coefficient de réduction",
                                        percent : $modifiedSlice.coef)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.ndTrimAvantAgeLegal >= 0
    }

    private func updateSlice() {
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.ndTrimAvantAgeLegal < $1.ndTrimAvantAgeLegal })

        dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année naissance, nb trimestre, age taux plein]

struct AgircAvantAgeLegalSliceAddView: View {
    @Transac var grid: GridAgircAvantAgeLegal
    @Environment(\.dismiss) private var dismiss
    @State private var newSlice = SliceAgircAvantAgeLegal(ndTrimAvantAgeLegal : 0,
                                                          coef                : 0)
    @State private var alertItem : AlertItem?

    private var toolBar: some View {
        HStack {
            Button("Annuler") {
                dismiss()
            }.buttonStyle(.bordered)
            Spacer()
            Text("Ajouter...").font(.title).fontWeight(.bold)
            Spacer()
            Button(OK", "action: addSlice)
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
                    IntegerEditView(label    : "Nombre de trimestres jusqu'à l'âge légal de départ à la retraite",
                                    integer  : $newSlice.ndTrimAvantAgeLegal,
                                    validity : .poz)
                    PercentNormEditView(label   : "Coefficient de réduction",
                                        percent : $newSlice.coef)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        newSlice.ndTrimAvantAgeLegal >= 0
    }

    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.ndTrimAvantAgeLegal != newSlice.ndTrimAvantAgeLegal }) else {
            self.alertItem = AlertItem(title         : Text("Le seuil existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        grid.append(newSlice)
        grid.sort(by: { $0.ndTrimAvantAgeLegal < $1.ndTrimAvantAgeLegal })

        dismiss()
    }
}

// MARK: - Preview

struct AgircAvantAgeLegalGridView_Previews: PreviewProvider {
    static func grid() -> GridAgircAvantAgeLegal {
        [ SliceAgircAvantAgeLegal(ndTrimAvantAgeLegal : 3,
                                  coef: 0.7),
          SliceAgircAvantAgeLegal(ndTrimAvantAgeLegal : 2,
                                  coef: 0.8),
          SliceAgircAvantAgeLegal(ndTrimAvantAgeLegal : 1,
                                  coef: 0.9)]
    }

    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: AgircAvantAgeLegalGridView(label: "Nom",
                                                                               grid : .init(source: grid()),
                                                                               updateDependenciesToModel: { })
                                .environmentObject(TestEnvir.dataStore)
                                .environmentObject(TestEnvir.model)
                                .environmentObject(TestEnvir.family)
                                .environmentObject(TestEnvir.simulation))
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
