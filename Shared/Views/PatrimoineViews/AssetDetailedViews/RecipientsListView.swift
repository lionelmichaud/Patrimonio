//
//  RecipientsListView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/02/2022.
//

import SwiftUI
import FamilyModel
import HelpersView

struct RecipientsListView : View {
    @EnvironmentObject var family: Family
    var title                    : String
    @Binding var recipients      : [String]
    @State private var alertItem : AlertItem?
    @State private var name      : String = ""
    
    var body: some View {
        List {
            if recipients.isEmpty {
                Text("Ajouter des " + title + " à l'aide du bouton '+'").foregroundColor(.red)
            } else {
                ForEach(recipients, id: \.self) { recipient in
                    EmptyView()
                    RecipientGroupBox(title     : title,
                                      recipient : recipient)
                }
                .onDelete(perform: deleteRecipient)
                .onMove(perform: moveRecipients)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                EditButton()
            }
            ToolbarItem(placement: .automatic) {
                Menu(content: menuAdd, label: menuAddLabel)
            }
        }
        .onChange(of: name, perform: addRecipient)
        .alert(item: $alertItem, content: newAlert)
    }
    
    func addRecipient(newPersonName: String) {
        // ajouter le nouveau copropriétaire
        recipients.append(newPersonName)
    }
    
    func deleteRecipient(at offsets: IndexSet) {
        guard recipients.count > 1 else {
            self.alertItem = AlertItem(title         : Text("Il doit y a voir au moins un " + title),
                                       dismissButton : .default(Text("OK")))
            return
        }
        // retirer la personne de la liste
        recipients.remove(atOffsets: offsets)
    }
    
    func moveRecipients(from indexes: IndexSet, to destination: Int) {
        recipients.move(fromOffsets: indexes, toOffset: destination)
    }
    
    func isAnRecipient(_ name: String) -> Bool {
        recipients.contains(name)
    }
    
    @ViewBuilder func menuAddLabel() -> some View {
        Image(systemName: "plus.circle.fill")
            .imageScale(.large)
            .padding()
    }
    
    @ViewBuilder func menuAdd() -> some View {
        Picker(selection: $name, label: Text("Personne")) {
            ForEach(family.members.items.filter { !isAnRecipient($0.displayName) }) { person in
                PersonNameRow(member: person)
            }
        }
    }
}

struct RecipientGroupBox: View {
    let title           : String
    @State var recipient : String
    
    var body: some View {
        GroupBox(label: Text(title)) {
            Label(recipient, systemImage: "person.fill").padding(.top, 8)
                .padding(.leading)
        }
        .groupBoxStyle(DefaultGroupBoxStyle())
    }
}

struct RecipientGroupBox_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            RecipientGroupBox(title: "Bénéficiaire", recipient: "Nom")
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("RecipientGroupBox")
    }
}

struct RecipientsListView_Previews: PreviewProvider {
    static var recipients = ["Nom 1", "Nom 2"]
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return Form {
            RecipientsListView(title: "Usufruitiers", recipients: .constant(recipients))
                .environmentObject(familyTest)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("RecipientsListView")
    }
}
