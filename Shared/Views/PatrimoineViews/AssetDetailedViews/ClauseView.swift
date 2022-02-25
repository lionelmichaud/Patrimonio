//
//  ClauseView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/02/2022.
//

import SwiftUI
import Ownership
import FamilyModel

struct ClauseView: View {
    @EnvironmentObject var family : Family
    @Binding var clause: LifeInsuranceClause
    let beneficiaireStr = "Bénéficiaire"
    let usufruitierStr  = "Bénéficiaire de l'Usufruitier"
    let nuPropStr       = "Bénéficiaires de la Nue-Propriété"

    var body: some View {
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

struct ClauseView_Previews: PreviewProvider {
    static func clause() -> LifeInsuranceClause {
        var theClause = LifeInsuranceClause()
        theClause.isOptional        = false
        theClause.isDismembered     = true
        theClause.usufructRecipient = "Conjoint"
        theClause.bareRecipients    = ["Enfant1"]
        return theClause
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return Form {
            ClauseView(clause: .constant(clause()))
        }
        .environmentObject(familyTest)
    }
}
