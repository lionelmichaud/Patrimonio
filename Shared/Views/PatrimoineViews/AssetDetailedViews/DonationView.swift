//
//  DonationView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/02/2022.
//

import SwiftUI
import Ownership
import Donation
import HelpersView

/// Edition d'une Donation
/// - Warning: Doit être intégrée dans une Form()
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
        var theClause = Clause()
        theClause.isOptional        = false
        theClause.isDismembered     = true
        theClause.usufructRecipient = "M. Lionel MICHAUD"
        theClause.bareRecipients    = ["Enfant 1", "Enfant 2"]

        var donation = Donation()
        donation.clause = theClause
        
        return donation
    }
    
    static var previews: some View {
        loadTestFilesFromBundle()
        return
            NavigationView {
                EmptyView()
                Form {
                    DonationView(donation: .constant(donation()))
                }
            }
            .environmentObject(familyTest)
            .preferredColorScheme(.dark)
            .previewDisplayName("DonationView")
    }
}
