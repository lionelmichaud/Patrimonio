//
//  TypeInvestEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 03/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Ownership
import AssetsModel
import PersonModel
import FamilyModel

// MARK: - Saisie du type d'investissement

struct TypeInvestEditView : View {
    @EnvironmentObject var family : Family
    @Binding var investType       : InvestementKind
    @State private var typeIndex  : Int
    @State private var isPeriodic : Bool
    @State private var clause     : LifeInsuranceClause
    let beneficiaireStr = "Bénéficiaire"
    let usufruitierStr  = "Bénéficiaire de l'Usufruitier"
    let nuPropStr       = "Bénéficiaires de la Nue-Propriété"

    var body: some View {
        Group {
            CaseWithAssociatedValuePicker<InvestementKind>(caseIndex: $typeIndex, label: "")
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: typeIndex) { newValue in
                    switch newValue {
                        case InvestementKind.pea.id:
                            self.investType = .pea
                        case InvestementKind.other.id:
                            self.investType = .other
                        case InvestementKind.lifeInsurance().id:
                            self.investType = .lifeInsurance(periodicSocialTaxes: self.isPeriodic,
                                                             clause             : self.clause)
                        default:
                            fatalError("InvestementType : Case out of bound")
                    }
                }
            if typeIndex == InvestementKind.lifeInsurance().id {
                Toggle("Prélèvement sociaux annuels", isOn: $isPeriodic)
                    .onChange(of: isPeriodic) { newValue in
                        self.investType = .lifeInsurance(periodicSocialTaxes: newValue,
                                                         clause             : self.clause)
                    }
                Toggle("Clause bénéficiaire à option (non démembrable)", isOn: $clause.isOptional)
                    .onChange(of: clause) { newValue in
                        var newClause = newValue
                        if newClause.isOptional {
                            newClause.isDismembered = false
                        }
                        self.investType = .lifeInsurance(periodicSocialTaxes: isPeriodic,
                                                         clause             : newClause)
                    }
                if !clause.isOptional {
                    Toggle("Clause bénéficiaire démembrée", isOn: $clause.isDismembered)
                }
                if clause.isDismembered && !clause.isOptional {
                    // usufruitier
                    Picker(selection : $clause.usufructRecipient,
                           label     : Text("Bénéficiaire de l'usufruit").foregroundColor(clause.usufructRecipient.isNotEmpty ? .blue : .red)) {
                        ForEach(family.members.items) { person in
                            PersonNameRow(member: person)
                        }
                    }
                    .padding(.leading)
                    // nue-propriétaires
                    NavigationLink(destination: RecipientsListView(title      : nuPropStr,
                                                                   recipients : $clause.bareRecipients).environmentObject(family)) {
                        HStack {
                            Text(nuPropStr)
                                .foregroundColor(clause.bareRecipients.isNotEmpty ? .blue : .red)
                                .padding(.leading)
                            Spacer()
                            Text(bareRecipientsSummary(clause: clause)).foregroundColor(.secondary)
                        }
                    }
                } else {
                    // bénéficiaires
                    NavigationLink(destination: OwnersListView(title  : beneficiaireStr,
                                                               owners : $clause.fullRecipients).environmentObject(family)) {
                        HStack {
                            Text(beneficiaireStr)
                                .foregroundColor(clause.fullRecipients.isNotEmpty ? .blue : .red)
                                .padding(.leading)
                            Spacer()
                            Text(fullRecipientsSummary(clause: clause)).foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Initializer

    init(investType: Binding<InvestementKind>) {
        self._investType = investType
        self._typeIndex  = State(initialValue: investType.wrappedValue.id)
        switch investType.wrappedValue {
            case .lifeInsurance(let periodicSocialTaxes, let clause):
                self._isPeriodic = State(initialValue: periodicSocialTaxes)
                self._clause     = State(initialValue: clause)
                
            default:
                self._isPeriodic = State(initialValue: false)
                self._clause     = State(initialValue: LifeInsuranceClause())
        }
    }

    // MARK: - Methods

    private func bareRecipientsSummary(clause: LifeInsuranceClause) -> String {
        if clause.bareRecipients.isEmpty {
            return ""
        } else if clause.bareRecipients.count == 1 {
            return clause.bareRecipients.first!
        } else {
            return "\(clause.bareRecipients.count) personnes"
        }
    }

    private func fullRecipientsSummary(clause: LifeInsuranceClause) -> String {
        if clause.fullRecipients.isEmpty {
            return ""
        } else if clause.fullRecipients.count == 1 {
            return clause.fullRecipients.first!.name
        } else {
            return "\(clause.fullRecipients.count) personnes"
        }
    }
}

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

struct TypeInvestEditView_Previews: PreviewProvider {
    static var family     = Family()

    static var previews: some View {
        Form {
            TypeInvestEditView(investType: .constant(InvestementKind.lifeInsurance()))
                .environmentObject(family)
        }
        .previewDisplayName("TypeInvestEditView")
    }
}
