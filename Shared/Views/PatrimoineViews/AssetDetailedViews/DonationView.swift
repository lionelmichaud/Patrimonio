//
//  DonationView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/02/2022.
//

import SwiftUI
import Ownership

struct DonationView: View {
    @Binding var donation: Donation
    
    var body: some View {
        IntegerEditView(label: "Année de la donation",
                        comment: "Fin d'année",
                        integer: $donation.atEndOfYear)
        ClauseView(clause: $donation.clause)
    }
}

struct DonationView_Previews: PreviewProvider {
    static func donation() -> Donation {
        var theClause = LifeInsuranceClause()
        theClause.isOptional        = false
        theClause.isDismembered     = true
        theClause.usufructRecipient = "Conjoint"
        theClause.bareRecipients    = ["Enfant1"]
        
        var donation = Donation()
        donation.clause = theClause
        
        return donation
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return Form {
            DonationView(donation: .constant(donation()))
        }
        .environmentObject(familyTest)
    }
}
