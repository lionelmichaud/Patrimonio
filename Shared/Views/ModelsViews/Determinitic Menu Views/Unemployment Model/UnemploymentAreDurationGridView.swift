//
//  UnemploymentAreDurationGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/02/2022.
//

import SwiftUI
import AppFoundation
import UnemployementModel
import HelpersView

typealias DurationSlice = UnemploymentCompensation.DurationSlice
typealias DurationGrid = [DurationSlice]

typealias UnemploymentAreDurationGridView = GridView<DurationSlice,
                                                      DurationSliceView,
                                                      DurationSliceAddView,
                                                      DurationSliceEditView>
extension UnemploymentAreDurationGridView {
    init(label                     : String,
         grid                      : Transac<[DurationSlice]>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = UnemploymentAreDurationGridView(label        : label,
                                               grid         : grid,
                                               displayView  : { slice in DurationSliceView(slice: slice) },
                                               addView      : { grid in DurationSliceAddView(grid: grid) },
                                               editView     : { grid, idx in DurationSliceEditView(grid: grid, idx: idx) },
                                               updateDependenciesToModel : updateDependenciesToModel)
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
                        percent : slice.reduction)
        }
    }
}

// MARK: - Edit a DurationSlice of the Grid [année naissance, nb trimestre, age taux plein]

struct DurationSliceEditView: View {
    @Transac private var grid: DurationGrid
    private var idx: Int
    @Environment(\.dismiss) private var dismiss
    @State private var modifiedSlice : DurationSlice
    @State private var alertItem     : AlertItem?

    init(grid : Transac<DurationGrid>,
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
                    IntegerEditView(label    : "A partir de",
                                    integer  : $modifiedSlice.fromAge,
                                    validity : .poz)
                    IntegerEditView(label    : "Nombre de mois d'indemnisation",
                                    integer  : $modifiedSlice.maxDuration,
                                    validity : .poz)
                    AmountEditView(label    : "Indemnité journalière minimale pour se voir appliqué la dégressivité",
                                   amount   : $modifiedSlice.reductionSeuilAlloc,
                                   validity : .poz)
                    IntegerEditView(label    : "Nombre de mois d'indemnisation avant dégressivité",
                                    integer  : $modifiedSlice.reductionAfter,
                                    validity : .poz)
                    PercentNormEditView(label   : "Dégressivité après ce délai",
                                        percent : $modifiedSlice.reduction)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        modifiedSlice.fromAge >= 0
    }

    private func updateSlice() {
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.fromAge < $1.fromAge })

        dismiss()
    }
}

// MARK: - Add a ExonerationSlice to the Grid [année naissance, nb trimestre, age taux plein]

struct DurationSliceAddView: View {
    @Transac var grid: DurationGrid
    @Environment(\.dismiss) private var dismiss
    @State private var newSlice = DurationSlice(fromAge             : 0,
                                                maxDuration         : 0,
                                                reduction           : 0,
                                                reductionAfter      : 0,
                                                reductionSeuilAlloc : 0)
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
                    IntegerEditView(label   : "A partir de",
                                    integer : $newSlice.fromAge,
                                    validity: .poz)
                    IntegerEditView(label   : "Nombre de mois d'indemnisation",
                                    integer : $newSlice.maxDuration,
                                    validity: .poz)
                    AmountEditView(label    : "Indemnité journalière minimale pour se voir appliqué la dégressivité",
                                   amount   : $newSlice.reductionSeuilAlloc,
                                   validity : .poz)
                    IntegerEditView(label   : "Nombre de mois d'indemnisation avant dégressivité",
                                    integer : $newSlice.reductionAfter,
                                    validity: .poz)
                    PercentNormEditView(label   : "Dégressivité après ce délai",
                                        percent : $newSlice.reduction)
                }
            }
            .textFieldStyle(.roundedBorder)
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

        grid.append(newSlice)
        grid.sort(by: { $0.fromAge < $1.fromAge })

        dismiss()
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
        NavigationView {
            NavigationLink("Test", destination: UnemploymentAreDurationGridView(label: "Nom",
                                                                                grid : .init(source: grid()),
                                                                                updateDependenciesToModel: { }))
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: 700.0, height: 400.0))
    }
}
