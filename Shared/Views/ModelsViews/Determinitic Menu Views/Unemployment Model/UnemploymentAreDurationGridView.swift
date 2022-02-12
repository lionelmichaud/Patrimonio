//
//  UnemploymentAreDurationGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/02/2022.
//

import SwiftUI
import UnemployementModel

typealias DurationSlice = UnemploymentCompensation.DurationSlice
typealias DurationGrid = [DurationSlice]

typealias UnemploymentAreDurationGridView = GridView<DurationSlice,
                                                     DurationSliceView,
                                                     DurationSliceAddView,
                                                     DurationSliceEditView>
extension UnemploymentAreDurationGridView {
    init(label : String,
         grid  : Binding<[DurationSlice]>) {
        self = UnemploymentAreDurationGridView(label          : label,
                                               grid           : grid,
                                               initializeGrid : { _ in },
                                               displayView    : { slice in DurationSliceView(slice: slice) },
                                               addView        : { grid in DurationSliceAddView(grid: grid) },
                                               editView       : { grid, idx in DurationSliceEditView(grid: grid, idx: idx) })
    }
}

// MARK: - Display a DurationSlice [année naissance, nb trimestre, age taux plein]

struct DurationSliceView: View {
    var slice: DurationSlice

    var body: some View {
        VStack {
            IntegerView(label   : "A partir de",
                        integer : slice.fromAge,
                        weight: .bold)
            IntegerView(label   : "Nombre de mois d'indemnisation",
                        integer : slice.maxDuration)
            AmountView(label   : "Indemnité journalière minimale pour se voir appliqué la dégressivité",
                       amount  : slice.reductionSeuilAlloc,
                       digit   : 2)
            IntegerView(label   : "Nombre de mois d'indemnisation avant dégressivité",
                        integer : slice.reductionAfter)
            PercentView(label   : "Dégressivité après ce délai",
                        percent : slice.reduction / 100.0)
        }
    }
}

// MARK: - Edit a DurationSlice of the Grid [année naissance, nb trimestre, age taux plein]

struct DurationSliceEditView: View {
    @Binding private var grid: DurationGrid
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : DurationSlice
    @State private var alertItem     : AlertItem?

    init(grid : Binding<DurationGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice =
        State(initialValue: DurationSlice(fromAge             : grid[idx].wrappedValue.fromAge,
                                          maxDuration         : grid[idx].wrappedValue.maxDuration,
                                          reduction           : grid[idx].wrappedValue.reduction,
                                          reductionAfter      : grid[idx].wrappedValue.reductionAfter,
                                          reductionSeuilAlloc : grid[idx].wrappedValue.reductionSeuilAlloc * 100.0))
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
                                    integer : $modifiedSlice.fromAge)
                    IntegerEditView(label   : "Nombre de mois d'indemnisation",
                                    integer : $modifiedSlice.maxDuration)
                    AmountEditView(label   : "Indemnité journalière minimale pour se voir appliqué la dégressivité",
                                   amount : $modifiedSlice.reductionSeuilAlloc)
                    IntegerEditView(label   : "Nombre de mois d'indemnisation avant dégressivité",
                                    integer : $modifiedSlice.reductionAfter)
                    PercentEditView(label   : "Dégressivité après ce délai",
                                    percent : $modifiedSlice.reduction)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.fromAge >= 0
    }

    private func updateSlice() {
        modifiedSlice.reduction /= 100.0 // [0, 100%] => [0, 1.0]
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.fromAge < $1.fromAge })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année naissance, nb trimestre, age taux plein]

struct DurationSliceAddView: View {
    @Binding var grid: DurationGrid
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = DurationSlice(fromAge             : 0,
                                                maxDuration         : 0,
                                                reduction           : 0,
                                                reductionAfter      : 0,
                                                reductionSeuilAlloc : 0)
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
                                    integer : $newSlice.fromAge)
                    IntegerEditView(label   : "Nombre de mois d'indemnisation",
                                    integer : $newSlice.maxDuration)
                    AmountEditView(label   : "Indemnité journalière minimale pour se voir appliqué la dégressivité",
                                   amount : $newSlice.reductionSeuilAlloc)
                    IntegerEditView(label   : "Nombre de mois d'indemnisation avant dégressivité",
                                    integer : $newSlice.reductionAfter)
                    PercentEditView(label   : "Dégressivité après ce délai",
                                    percent : $newSlice.reduction)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        newSlice.fromAge >= 0
    }

    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.fromAge != newSlice.fromAge }) else {
            self.alertItem = AlertItem(title         : Text("Le seuil existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        newSlice.reduction /= 100.0 // [0, 100%] => [0, 1.0]
        grid.append(newSlice)
        grid.sort(by: { $0.fromAge < $1.fromAge })

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Preview

struct UnemploymentAreDurationGridView_Previews: PreviewProvider {
    static func grid() -> DurationGrid {
        [ DurationSlice(fromAge             : 55,
                        maxDuration         : 0,
                        reduction           : 0,
                        reductionAfter      : 0,
                        reductionSeuilAlloc : 0),
          DurationSlice(fromAge             : 56,
                        maxDuration         : 0,
                        reduction           : 0,
                        reductionAfter      : 0,
                        reductionSeuilAlloc : 0),
          DurationSlice(fromAge             : 57,
                        maxDuration         : 0,
                        reduction           : 0,
                        reductionAfter      : 0,
                        reductionSeuilAlloc : 0)]
    }

    static var previews: some View {
        loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: UnemploymentAreDurationGridView(label: "Nom",
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
