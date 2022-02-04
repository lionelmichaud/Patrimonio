//
//  PointGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 01/02/2022.
//

import SwiftUI
import AppFoundation
import Statistics

typealias PointGrid = [Point]

// MARK: - Editeur de Courbe [x, y]

struct VerifiedPointGridView : View {
    let label: String
    @Binding var grid: PointGrid
    
    var body: some View {
        VStack(alignment: .leading) {
            if formIsValid() {
                Text("La grille est valide car le somme des probabilités = 100 %")
                    .foregroundColor(.green)
                    .padding(.horizontal)

            } else {
                Text("La grille est invalide car le somme des probabilités n'est pas = 100 % (actuellement \(sumOfProbability, specifier: "%.2f") %)")
                    .foregroundColor(.red)
                    .padding(.horizontal)

            }
            PointGridView(label: label,
                          grid: $grid)
        }
    }
    
    var sumOfProbability: Double {
        grid.sum(for: \.y) * 100.0
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        // vérifier que la somme des probabilité est égale à 1.0
        sumOfProbability == 100.0
    }
    
}

typealias PointGridView = GridView<Point, PointView, PointAddView, PointEditView>
extension PointGridView {
    init(label : String,
         grid  : Binding<[Point]>) {
        self = PointGridView(label          : label,
                             grid           : grid,
                             gridIsValid    : { grid in grid.sum(for: \.y) == 1.0 },
                             initializeGrid : { _ in  },
                             displayView    : { point in PointView(point: point) },
                             addView        : { grid in PointAddView(grid: grid) },
                             editView       : { grid, idx in PointEditView(grid: grid, idx: idx) })
    }
}

// MARK: - Display a Point of a curve [x, y]

struct PointView: View {
    var point: Point
    
    var body: some View {
        HStack {
            Group { Text("X = ") + Text(point.x as NSObject, formatter: decimalFormatter) }
                .padding(.trailing)
            Text("Probabilité(X) = ") + Text(point.y as NSObject, formatter: decimalFormatter)
        }
    }
}

// MARK: - Edit a Point of a curve [x, y]

struct PointEditView: View {
    @Binding private var grid: PointGrid
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : Point
    @State private var alertItem     : AlertItem?
    
    init(grid : Binding<PointGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue : Point(grid[idx].wrappedValue.x,
                                                    grid[idx].wrappedValue.y * 100.0))
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
                //.disabled(!formIsValid())
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
                    AmountEditView(label    : "X",
                                   amount   : $modifiedSlice.x,
                                   currency : false)
                    AmountEditView(label    : "Probabilité(X)",
                                   amount   : $modifiedSlice.y,
                                   currency : false)
                    Text("Somme des probabilités = (\(sumOfProbability * 100.0, specifier: "%.2f") %)")
                        .foregroundColor(formIsValid() ? .green : .red)
                    if !formIsValid() {
                        Text("La somme des probabilités doit être égale à 100 %")
                            .foregroundColor(.red)
                    }
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    var sumOfProbability: Double {
        grid.sum(for: \.y) - grid[idx].y + modifiedSlice.y / 100.0
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        // vérifier que la somme des probabilité est égale à 1.0
        sumOfProbability == 1.0
    }
    
    private func updateSlice() {
        grid[idx] = Point(modifiedSlice.x, modifiedSlice.y / 100.0) // [0, 100%] => [0, 1.0]
        grid.sort(by: { $0.x < $1.x })
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a Point of a curve [x, y]

struct PointAddView: View {
    @Binding var grid: PointGrid
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = Point(0, 0)
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
                    AmountEditView(label    : "X",
                                   amount   : $newSlice.x,
                                   currency : false)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    var sumOfProbability: Double {
        grid.sum(for: \.y) + newSlice.y / 100.0
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private func formIsValid() -> Bool {
        // vérifier que la somme des probabilité est égale à 1.0
        sumOfProbability == 1.0
    }
    
    private func addSlice() {
        // vérifier que le nouveau X n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.x != newSlice.x }) else {
            self.alertItem = AlertItem(title         : Text("La valeur de X existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        
        newSlice.y /= 100.0 // [0, 100%] => [0, 1.0]
        grid.append(newSlice)
        grid.sort(by: { $0.x < $1.x })
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Previews

struct PointView_Previews: PreviewProvider {
    static var previews: some View {
        PointView(point: Point(2.5, -3.4))
            .previewLayout(.fixed(width: 500, height: 50))
    }
}

struct PointGridView_Previews: PreviewProvider {
    static func grid() -> PointGrid {
        [ Point(1, 0.1),
          Point(2, 0.7),
          Point(3, 0.2)]
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return
            NavigationView {
                NavigationLink("Test", destination: PointGridView(label: "Nom",
                                                                  grid: .constant(grid()))
                                .environmentObject(modelTest)
                                .environmentObject(familyTest)
                                .environmentObject(simulationTest)
                                .environmentObject(viewModel))
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: 300.0))
    }
}

struct VerifiedPointGridView_Previews: PreviewProvider {
    static func grid() -> PointGrid {
        [ Point(1, 0.1),
          Point(2, 0.7),
          Point(3, 0.2)]
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return
            NavigationView {
                NavigationLink("Test", destination: VerifiedPointGridView(label: "Courbe",
                                                                          grid: .constant(grid()))
                                .environmentObject(modelTest)
                                .environmentObject(familyTest)
                                .environmentObject(simulationTest)
                                .environmentObject(viewModel))
            }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: 300.0))
    }
}
