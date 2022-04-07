//
//  AgircApresAgeLegalGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import AppFoundation
import RetirementModel
import HelpersView

typealias SliceAgircApresAgeLegal = RegimeAgirc.SliceApresAgeLegal
typealias GridAgircApresAgeLegal = [SliceAgircApresAgeLegal]

typealias AgircApresAgeLegalGridView = GridView<SliceAgircApresAgeLegal,
                                                AgircApresAgeLegalSliceView,
                                                AgircApresAgeLegalSliceAddView,
                                                AgircApresAgeLegalSliceEditView>
extension AgircApresAgeLegalGridView {
    init(label : String,
         grid  : Transac<[SliceAgircApresAgeLegal]>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = AgircApresAgeLegalGridView(label          : label,
                                          grid           : grid,
                                          displayView    : { slice in AgircApresAgeLegalSliceView(slice: slice) },
                                          addView        : { grid in AgircApresAgeLegalSliceAddView(grid: grid) },
                                          editView       : { grid, idx in AgircApresAgeLegalSliceEditView(grid: grid, idx: idx) },
                                          updateDependenciesToModel : updateDependenciesToModel)
    }
}

// MARK: - Display a SliceAgircApresAgeLegal [année naissance, nb trimestre, age taux plein]

struct AgircApresAgeLegalSliceView: View {
    var slice: SliceAgircApresAgeLegal

    var body: some View {
        VStack {
            IntegerView(label   : "Nombre de trimestres manquant",
                        integer : slice.nbTrimManquant,
                        weight  : .bold)
            IntegerView(label   : "Nombre de trimestres audelà de l'âge légal de départ à la retraite",
                        integer : slice.ndTrimPostAgeLegal)
            PercentNormView(label   : "Coefficient de réduction",
                            percent : slice.coef)
        }
    }
}

// MARK: - Edit a SliceAgircApresAgeLegal of the Grid [année naissance, nb trimestre, age taux plein]

struct AgircApresAgeLegalSliceEditView: View {
    @Transac private var grid: GridAgircApresAgeLegal
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : SliceAgircApresAgeLegal
    @State private var alertItem     : AlertItem?

    init(grid : Transac<GridAgircApresAgeLegal>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue: grid[idx].wrappedValue)
    }

    private var toolBar: some View {
        HStack {
            Button("Annuler",
                   role: .cancel,
                   action : { self.presentationMode.wrappedValue.dismiss() })
            Spacer()
            Text("Modifier").font(.title).fontWeight(.bold)
            Spacer()
            Button("OK",
                   action : updateSlice)
                .disabled(!formIsValid())
                .alert(item: $alertItem, content: newAlert)
        }
        .buttonStyle(.bordered)
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
                    IntegerEditView(label   : "Nombre de trimestres manquant",
                                    integer : $modifiedSlice.nbTrimManquant,
                                    validity: .poz)
                    IntegerEditView(label   : "Nombre de trimestres au-delà de l'âge légal de départ à la retraite",
                                    integer : $modifiedSlice.ndTrimPostAgeLegal,
                                    validity: .poz)
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
        modifiedSlice.nbTrimManquant >= 0
    }

    private func updateSlice() {
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.nbTrimManquant < $1.nbTrimManquant })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année naissance, nb trimestre, age taux plein]

struct AgircApresAgeLegalSliceAddView: View {
    @Transac var grid: GridAgircApresAgeLegal
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = SliceAgircApresAgeLegal(nbTrimManquant     : 0,
                                                          ndTrimPostAgeLegal : 0,
                                                          coef               : 0)
    @State private var alertItem : AlertItem?

    private var toolBar: some View {
        HStack {
            Button("Annuler",
                   role: .cancel,
                   action : { self.presentationMode.wrappedValue.dismiss() })
            Spacer()
            Text("Ajouter...").font(.title).fontWeight(.bold)
            Spacer()
            Button("OK",
                   action: addSlice)
                .disabled(!formIsValid())
                .alert(item: $alertItem, content: newAlert)
        }
        .buttonStyle(.bordered)
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
                    IntegerEditView(label   : "Nombre de trimestres manquant",
                                    integer : $newSlice.nbTrimManquant)
                    IntegerEditView(label   : "Nombre de trimestres au-delà de l'âge légal de départ à la retraite",
                                    integer : $newSlice.ndTrimPostAgeLegal)
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
        newSlice.nbTrimManquant >= 0
    }

    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.nbTrimManquant != newSlice.nbTrimManquant }) else {
            self.alertItem = AlertItem(title         : Text("L'élément existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        grid.append(newSlice)
        grid.sort(by: { $0.nbTrimManquant < $1.nbTrimManquant })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

struct AgircApresAgeLegalGridView_Previews: PreviewProvider {
    static func grid() -> GridAgircApresAgeLegal {
        [ SliceAgircApresAgeLegal(nbTrimManquant  : 1,
                                  ndTrimPostAgeLegal : 3,
                                  coef: 0.7),
          SliceAgircApresAgeLegal(nbTrimManquant  : 2,
                                  ndTrimPostAgeLegal : 2,
                                  coef: 0.8),
          SliceAgircApresAgeLegal(nbTrimManquant  : 3,
                                  ndTrimPostAgeLegal : 1,
                                  coef: 0.9)]
    }

    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: AgircApresAgeLegalGridView(label: "Nom",
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
