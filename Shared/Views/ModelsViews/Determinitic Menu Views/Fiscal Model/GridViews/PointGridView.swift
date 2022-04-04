//
//  PointGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 01/02/2022.
//

import SwiftUI
import AppFoundation
import Statistics
import HelpersView

extension ArrayOfPoint {
    /// Garantir que la sommes des probabilités = 1.0
    /// en ajustant la probabilité du(des) dernièr(s) point(s) de la grille
    mutating func normalizeY() {
        var exceeding = self.sum(for: \.y) - 1.0
        
        switch exceeding {
            case 0.0:
                break
                
            case 0.0...:
                // enlever aux derniers éléments
                for i in self.indices.reversed() {
                    let removed = Swift.min(exceeding, self[i].y)
                    self[self.endIndex - 1].y -= removed
                    exceeding -= removed
                    if exceeding <= 0 { break }
                }
                
            default:
                // ajouter au dernier élément
                self[self.endIndex - 1].y += -exceeding
        }
    }
    
    /// Garantir que la sommes des probabilités = 1.0 sans affecter le point
    /// de la grille qui vient d'être modifié.
    /// - Parameter idx: index du point de la grille qui vient d'être modifié
    mutating func normalizeY(idx: Int) {
        var exceeding = self.sum(for: \.y) - 1.0
        
        switch exceeding {
            case 0.0:
                break
                
            case 0.0...:
                // enlever aux derniers éléments
                for i in self.indices.reversed() where i != idx {
                    let removed = Swift.min(exceeding, self[i].y)
                    self[i].y -= removed
                    exceeding -= removed
                    if exceeding <= 0 { break }
                }
                
            default:
                if idx == self.endIndex - 1 {
                    // ajouter à l'avant-dernier élément
                    self[idx-1].y -= exceeding
                } else {
                    // ajouter au dernier élément
                    self[self.endIndex - 1].y -= exceeding
                }
        }
    }
}

// MARK: - Editeur de Courbe [x, p]

struct VerifiedPointGridView : View {
    let label: String
    @Binding var grid: ArrayOfPoint
    
    var body: some View {
        VStack(alignment: .leading) {
            if formIsValid {
                Text("La grille est valide car le somme des probabilités = 100 %")
                    .foregroundColor(.green)
                    .padding(.horizontal)

            } else {
                Text("La grille est invalide car le somme des probabilités n'est pas = 100 % (actuellement \(sumOfProbability, specifier: "%.2f") %)")
                    .foregroundColor(.red)
                    .padding(.horizontal)

            }
            PointGridView(label: label,
                          grid: $grid.transaction(),
                          updateDependenciesToModel: { })
        }
    }
    
    private var sumOfProbability: Double {
        grid.sum(for: \.y) * 100.0
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    private var formIsValid: Bool {
        // vérifier que la somme des probabilité est égale à 1.0
        sumOfProbability == 100.0
    }
    
}

typealias PointGridView = GridView<Point,
                                    PointView,
                                    PointAddView,
                                    PointEditView>
extension PointGridView {
    init(label : String,
         grid  : Transac<ArrayOfPoint>,
         updateDependenciesToModel : @escaping ( ) -> Void) {
        self = PointGridView(label          : label,
                             grid           : grid,
                             gridIsValid    : { grid in grid.sum(for: \.y) == 1.0 },
                             initializeGrid : { grid in grid.normalizeY()},
                             displayView    : { point in PointView(point: point) },
                             addView        : { grid in PointAddView(grid: grid) },
                             editView       : { grid, idx in PointEditView(grid: grid, idx: idx) },
                             updateDependenciesToModel: updateDependenciesToModel)
    }
}

// MARK: - Display a Point of a curve [x, p]

struct PointView: View {
    var point: Point
    
    var body: some View {
        HStack {
            Group { Text("X = ") + Text(point.x as NSObject, formatter: decimalFormatter) }
                .padding(.trailing)
            Text("Probabilité(X) = ") + Text((point.y) as NSObject, formatter: percentFormatter)
        }
    }
}

// MARK: - Edit a Point of a curve [x, p]

struct PointEditView: View {
    @Transac private var grid: ArrayOfPoint
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : Point
    @State private var alertItem     : AlertItem?
    
    init(grid : Transac<ArrayOfPoint>,
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
                .buttonStyle(.bordered)
            Spacer()
            Text("Modifier").font(.title).fontWeight(.bold)
            Spacer()
            Button(action : updateSlice,
                   label  : { Text("OK") })
                .buttonStyle(.bordered)
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
                    PercentEditView(label  : "Probabilité(X)",
                                   percent : $modifiedSlice.y)
                }
            }
            .textFieldStyle(.roundedBorder)
        }
    }
    
    private func updateSlice() {
        // vérifier que le nouveau X n'existe pas déjà dans la grille
        for i in grid.indices {
            if i != idx && grid[i].x == modifiedSlice.x {
                self.alertItem = AlertItem(title         : Text("La valeur de X existe déjà dans la grille"),
                                           dismissButton : .default(Text("OK")))
                return
            }
        }

        var gridCopy = grid
        gridCopy[idx] = Point(modifiedSlice.x, modifiedSlice.y / 100.0) // [0, 100%] => [0, 1.0]
        // garantir que la sommes des probabilités = 1.0
        gridCopy.normalizeY(idx: idx)
        gridCopy.sort(by: { $0.x < $1.x })
        
        // vérifier qu'il n'y a pas de probabilité négative
        guard gridCopy.allSatisfy({ $0.y >= 0.0 }) else {
            self.alertItem = AlertItem(title         : Text("Une probabilité est négative"),
                                       dismissButton : .default(Text("OK")))
            return
        }

        grid = gridCopy

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a Point of a curve [x, p]

struct PointAddView: View {
    @Transac var grid: ArrayOfPoint
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = Point(0, 0)
    @State private var alertItem : AlertItem?
    
    private var toolBar: some View {
        HStack {
            Button(action: { self.presentationMode.wrappedValue.dismiss() },
                   label: { Text("Annuler") })
                .buttonStyle(.bordered)
            Spacer()
            Text("Ajouter...").font(.title).fontWeight(.bold)
            Spacer()
            Button(action: addSlice,
                   label: { Text("OK") })
                .buttonStyle(.bordered)
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
            .textFieldStyle(.roundedBorder)
        }
    }
    
    private func addSlice() {
        // vérifier que le nouveau X n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.x != newSlice.x }) else {
            self.alertItem = AlertItem(title         : Text("La valeur de X existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        newSlice.y /= 100.0 // [0, 100%] => [0, 1.0]
        var gridCopy = grid
        gridCopy.append(newSlice)
        gridCopy.sort(by: { $0.x < $1.x })

        grid = gridCopy
        
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
    static func grid() -> ArrayOfPoint {
        [ Point(1, 0.1),
          Point(2, 0.7),
          Point(3, 0.2)]
    }
    
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return
            NavigationView {
                NavigationLink("Test", destination: PointGridView(label: "Nom",
                                                                  grid : .init(source: grid()),
                                                                  updateDependenciesToModel: { }))
            }
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: 300.0))
    }
}

struct VerifiedPointGridView_Previews: PreviewProvider {
    static func grid() -> ArrayOfPoint {
        [ Point(1, 0.1),
          Point(2, 0.7),
          Point(3, 0.2)]
    }
    
    static var previews: some View {
        NavigationView {
            NavigationLink("Test", destination: VerifiedPointGridView(label: "Courbe",
                                                                      grid: .constant(grid())))
        }
        .preferredColorScheme(.dark)
        .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: 300.0))
    }
}
