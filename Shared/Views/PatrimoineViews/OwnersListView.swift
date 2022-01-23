//
//  OwnersListView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 03/05/2021.
//

import SwiftUI
import Ownership
import PersonModel
import FamilyModel

struct OwnersListView: View {
    let title                    : String
    @Binding var owners          : Owners
    @EnvironmentObject var family: Family
    @State private var alertItem : AlertItem?
    @State private var name      : String = ""
    
    var body: some View {
        List {
            if owners.isEmpty {
                Text("Ajouter des " + title + " à l'aide du bouton '+'").foregroundColor(.red)
            } else {
                ForEach(owners, id: \.self) { owner in
                    OwnerGroupBox(title  : title,
                                  owner  : owner,
                                  owners : $owners)
                }
                .onDelete(perform: deleteOwner)
                .onMove(perform: moveOwners)
                PercentView(label: "Total " + title + "s (doit être de 100%)", percent: owners.sumOfOwnedFractions / 100.0)
                    .foregroundColor(owners.isvalid ? .blue : .red)
            }
        }
        .navigationTitle(title+"s")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .automatic) {
                Menu(content: menuAdd, label: menuAddLabel)
            }
        }
        .onChange(of: name, perform: addOwner)
        .onAppear(perform: checkPercentageOfOwnership)
        .alert(item: $alertItem, content: newAlert)
    }
    
    func checkPercentageOfOwnership() {
        if !owners.isEmpty && !(owners.sumOfOwnedFractions == 100.0) {
            self.alertItem = AlertItem(title         : Text("Vérifier la part en % de chaque " + title),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    func addOwner(newPersonName: String) {
        // ajouter le nouveau copropriétaire
        let newOwner = Owner(name: newPersonName, fraction: owners.isEmpty ? 100.0 : 0.0)
        owners.append(newOwner)
    }
    
    func deleteOwner(at offsets: IndexSet) {
        // Empêcher de supprimer la dernière personne
        guard owners.count > 1 else {
            self.alertItem = AlertItem(title         : Text("Il doit y a voir au moins un " + title),
                                       dismissButton : .default(Text("OK")))
            return
        }
        // retirer la personne de la liste
        owners.remove(atOffsets: offsets)
        
        if owners.count == 1 {
            owners[0].fraction = 100.0
        } else {
            // demander à l'utilisateur de mettre à jour les % manuellement
            self.alertItem = AlertItem(title         : Text("Vérifier la part en % de chaque " + title),
                                       dismissButton : .default(Text("OK")))
        }
    }
    
    func moveOwners(from indexes: IndexSet, to destination: Int) {
        owners.move(fromOffsets: indexes, toOffset: destination)
    }
    
    func isAnOwner(_ name: String) -> Bool {
        owners.contains(where: { $0.name == name })
    }
    
    @ViewBuilder func menuAddLabel() -> some View {
        Image(systemName: "plus.circle.fill")
            .imageScale(.large)
            .padding()
    }
    
    @ViewBuilder func menuAdd() -> some View {
        Picker(selection: $name, label: Text("Personne")) {
            ForEach(family.members.items.filter { !isAnOwner($0.displayName) }) { person in
                PersonNameRow(member: person)
            }
        }
    }
}

struct OwnersListView_Previews: PreviewProvider {
    static var family     = Family()
    static let goodOwner  = Owner(name : "Lionel Michaud", fraction : 100)
    static let goodOwners = [OwnersListView_Previews.goodOwner]
    static let badOwner   = Owner(name  : "Lionel Michaud", fraction  : 50)
    static let badOwners  = [OwnersListView_Previews.badOwner]

    static var previews: some View {
        Group {
            OwnersListView(title: "Usufruitier",
                           owners: .constant(goodOwners))
                .preferredColorScheme(.dark)
                .environmentObject(family)
            OwnersListView(title: "Usufruitier",
                           owners: .constant(badOwners))
                .preferredColorScheme(.dark)
                .environmentObject(family)
        }
    }
}
