//
//  RateGridView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 23/01/2022.
//

import SwiftUI
import AppFoundation
import ModelEnvironment
import FamilyModel

struct RateGridView: View {
    let label: String
    @Binding var grid: RateGrid
    @EnvironmentObject private var viewModel  : DeterministicViewModel
    @EnvironmentObject private var model      : Model
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var simulation : Simulation
    @State private var selection : RateSlice?
    @State private var alertItem : AlertItem?
    @State private var showingAddSheet  = false
    @State private var showingEditSheet = false
    @State private var selectedSliceIdx : Int = 0

    var body: some View {
        /// barre d'outils de la Liste
        VStack(alignment: .leading) {
            HStack {
                Button(action : { withAnimation { showingAddSheet = true } },
                       label  : {
                        Label("Ajouter un seuil", systemImage: "plus.circle.fill")
                       })
                    .sheet(isPresented: $showingAddSheet) {
                        RateSliceAddView(grid: $grid)
                    }
                Spacer()
                HStack {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.accentColor)
                    EditButton()
                }
            }
            .padding([.horizontal,.top])
            
            /// Liste
            List(selection: $selection) {
                ForEach(grid, id: \.self) { slice in
                    RateSliceView(slice: slice)
                        .onTapGesture(count   : 2,
                                      perform : {
                            selectedSliceIdx = grid.firstIndex(of: slice)!
                            showingEditSheet = true
                        })
                        .sheet(isPresented: $showingEditSheet) {
                            RateSliceEditView(grid : $grid,
                                              idx  : selectedSliceIdx)
                        }
                }
                .onDelete(perform: deleteSlices)
                .onChange(of: grid) { _ in viewModel.isModified = true }
            }
        }
        .alert(item: $alertItem, content: newAlert)
        .navigationTitle(label)
        /// barre d'outils de la NavigationView
        .toolbar {
            ToolbarItem(placement: .automatic) {
                DiskButton(text   : "Modifier le Patron",
                           action : {
                            alertItem = applyChangesToTemplateAlert(
                                viewModel: viewModel,
                                model: model,
                                notifyTemplatFolderMissing: {
                                    alertItem =
                                        AlertItem(title         : Text("Répertoire 'Patron' absent"),
                                                  dismissButton : .default(Text("OK")))
                                },
                                notifyFailure: {
                                    alertItem =
                                        AlertItem(title         : Text("Echec de l'enregistrement"),
                                                  dismissButton : .default(Text("OK")))
                                })
                           })
            }
            ToolbarItem(placement: .automatic) {
                FolderButton(action : {
                    alertItem = applyChangesToOpenDossierAlert(
                        viewModel  : viewModel,
                        model      : model,
                        family     : family,
                        simulation : simulation)
                })
                .disabled(!viewModel.isModified)
            }
        }
    }
    
    private func deleteSlices(at offsets: IndexSet) {
        grid.remove(atOffsets: offsets)
        try! grid.initialize()
    }
}

// MARK: - Display a RateSlice

struct RateSliceView: View {
    var slice: RateSlice

    var body: some View {
        HStack {
            AmountView(label   : "Seuil",
                       amount  : slice.floor)
            Spacer(minLength: 50)
            PercentView(label   : "Taux",
                        percent : slice.rate)
        }
    }
}

// MARK: - Edit a RateSlice of the Grid

struct RateSliceEditView: View {
    @Binding private var grid: RateGrid
    private var idx: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var modifiedSlice : RateSlice
    @State private var alertItem     : AlertItem?

    init(grid : Binding<RateGrid>,
         idx  : Int) {
        self.idx       = idx
        _grid          = grid
        _modifiedSlice = State(initialValue : RateSlice(floor : grid[idx].wrappedValue.floor,
                                                        rate  : grid[idx].wrappedValue.rate * 100.0))
    }

    var toolBar: some View {
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
                    AmountEditView(label  : "Seuil",
                                   amount : $modifiedSlice.floor)
                    PercentEditView(label   : "Taux",
                                    percent : $modifiedSlice.rate)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }

    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    func formIsValid() -> Bool {
        modifiedSlice.floor >= 0
    }

    private func updateSlice() {
        modifiedSlice.rate /= 100.0 // [0, 100%] => [0, 1.0]
        grid[idx] = modifiedSlice
        grid.sort(by: { $0.floor < $1.floor })
        try! grid.initialize()

        self.presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Add a RateSlice to the Grid

struct RateSliceAddView: View {
    @Binding var grid: RateGrid
    @Environment(\.presentationMode) var presentationMode
    @State private var newSlice = RateSlice(floor: 0, rate: 10)
    @State private var alertItem : AlertItem?

    var toolBar: some View {
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
                    AmountEditView(label   : "Seuil",
                                   amount  : $newSlice.floor)
                    PercentEditView(label   : "Taux",
                                    percent : $newSlice.rate)
                }
            }
            .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
    
    /// Vérifie que le formulaire est valide
    /// - Returns: vrai si le formulaire est valide
    func formIsValid() -> Bool {
        newSlice.floor >= 0
    }
    
    private func addSlice() {
        // vérifier que le nouveau seuil n'existe pas déjà dans la grille
        guard grid.allSatisfy({ $0.floor != newSlice.floor }) else {
            self.alertItem = AlertItem(title         : Text("Le seuil existe déjà dans la grille"),
                                       dismissButton : .default(Text("OK")))
            return
        }
        
        newSlice.rate /= 100.0 // [0, 100%] => [0, 1.0]
        grid.append(newSlice)
        grid.sort(by: { $0.floor < $1.floor })
        try! grid.initialize()
        
        self.presentationMode.wrappedValue.dismiss()
    }
}

struct RateSliceView_Previews: PreviewProvider {
    static var previews: some View {
        RateSliceView(slice: RateSlice(floor: 1000.0,
                                       rate: 10.0))
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: /*@START_MENU_TOKEN@*/100.0/*@END_MENU_TOKEN@*/))
    }
}

struct RateGridView_Previews: PreviewProvider {
    static func grid() -> RateGrid {
        [ RateSlice(floor:    0.0, rate: 10.0),
          RateSlice(floor: 1000.0, rate: 20.0),
          RateSlice(floor: 2000.0, rate: 30.0)]
    }

    static var previews: some View {
        loadTestFilesFromBundle()
        let viewModel = DeterministicViewModel(using: modelTest)
        return RateGridView(label: "Nom",
                            grid: .constant(grid()))
            .preferredColorScheme(.dark)
            .environmentObject(modelTest)
            .environmentObject(familyTest)
            .environmentObject(simulationTest)
            .environmentObject(viewModel)
            .preferredColorScheme(.dark)
            .previewLayout(.fixed(width: /*@START_MENU_TOKEN@*/500.0/*@END_MENU_TOKEN@*/, height: 300.0))
    }
}
