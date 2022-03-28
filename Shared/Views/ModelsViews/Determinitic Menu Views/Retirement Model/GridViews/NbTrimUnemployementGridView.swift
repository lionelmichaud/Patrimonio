//
//  NbTrimUnemployementGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 02/02/2022.
//

import SwiftUI
import AppFoundation
import RetirementModel
import HelpersView

typealias SliceNbTrimUnemployement = RegimeGeneral.SliceUnemployement
typealias GridNbTrimUnemployement = [SliceNbTrimUnemployement]

typealias NbTrimUnemployementGridView = GridView2<SliceNbTrimUnemployement,
                                                 NbTrimUnemployementSliceView,
                                                 NbTrimUnemployementSliceAddView,
                                                 NbTrimUnemployementSliceEditView>
extension NbTrimUnemployementGridView {
    init(label : String,
         grid  : Transac<[SliceNbTrimUnemployement]>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = NbTrimUnemployementGridView(label       : label,
                                           grid        : grid,
                                           displayView : { slice in NbTrimUnemployementSliceView(slice: slice) },
                                           addView     : { grid in NbTrimUnemployementSliceAddView(grid: grid) },
                                           editView    : { grid, idx in NbTrimUnemployementSliceEditView(grid: grid, idx: idx) },
                                           updateDependenciesToModel : updateDependenciesToModel)
    }
}

// MARK: - Display a SliceNbTrimUnemployement [année naissance, nb trimestre, age taux plein]

struct NbTrimUnemployementSliceView: View {
    var slice: SliceNbTrimUnemployement

    var body: some View {
        VStack {
            IntegerView(label   : "Nombre de trimestres acquis",
                        integer : slice.nbTrimestreAcquis)
            IntegerView(label   : "Nombre de trimestres de chômage non indemnisés",
                        integer : slice.nbTrimNonIndemnise)
        }
    }
}

// MARK: - Edit a SliceNbTrimUnemployement of the Grid [année naissance, nb trimestre, age taux plein]

struct NbTrimUnemployementSliceEditView: View {
    @Transac private var grid: GridNbTrimUnemployement
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : SliceNbTrimUnemployement
    @State private var alertItem     : AlertItem?

    init(grid : Transac<GridNbTrimUnemployement>,
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
                    IntegerEditView(label   : "Nombre de trimestres acquis",
                                    integer : $modifiedSlice.nbTrimestreAcquis)
                    //Spacer(minLength: 50)
                    IntegerEditView(label   : "Nombre de trimestres de chômage non indemnisés",
                                    integer : $modifiedSlice.nbTrimNonIndemnise)
                    //Spacer(minLength: 50)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.nbTrimestreAcquis >= 0
    }

    private func updateSlice() {
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.nbTrimestreAcquis < $1.nbTrimestreAcquis })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année naissance, nb trimestre, age taux plein]

struct NbTrimUnemployementSliceAddView: View {
    @Transac var grid: GridNbTrimUnemployement
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = SliceNbTrimUnemployement(nbTrimestreAcquis  : 0,
                                                           nbTrimNonIndemnise : 0)
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
                    IntegerEditView(label   : "Nombre de trimestres acquis",
                                    integer : $newSlice.nbTrimestreAcquis)
                    IntegerEditView(label   : "Nb trimestre",
                                    integer : $newSlice.nbTrimNonIndemnise)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        newSlice.nbTrimestreAcquis >= 0
    }

    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.nbTrimestreAcquis != newSlice.nbTrimestreAcquis }) else {
            self.alertItem = AlertItem(title         : Text("Le seuil existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        grid.append(newSlice)
        grid.sort(by: { $0.nbTrimestreAcquis < $1.nbTrimestreAcquis })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

struct NbTrimUnemployementGridView_Previews: PreviewProvider {
    static func grid() -> GridNbTrimUnemployement {
        [ SliceNbTrimUnemployement(nbTrimestreAcquis  : 1964,
                                   nbTrimNonIndemnise : 62),
          SliceNbTrimUnemployement(nbTrimestreAcquis  : 1965,
                                   nbTrimNonIndemnise : 64),
          SliceNbTrimUnemployement(nbTrimestreAcquis  : 1966,
                                   nbTrimNonIndemnise : 65)]
    }

    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: NbTrimUnemployementGridView(label: "Nom",
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
