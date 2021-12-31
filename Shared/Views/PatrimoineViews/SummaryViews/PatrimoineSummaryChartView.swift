//
//  PatrimoineSummaryChartView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 30/12/2021.
//

import SwiftUI
import AppFoundation
import Ownership
import FamilyModel
import PatrimoineModel
import Charts

struct PatrimoineSummaryChartView: View {
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    
    var body: some View {
        VStack {
            HStack {
                FamilyMembersPatrimoineSharesView(title      : "REPARTITION\nDU\nPATRIMOINE",
                                                  family     : family,
                                                  patrimoine : patrimoine,
                                                  year       : Int(uiState.patrimoineViewState.evalDate))
                FamilyMembersPatrimoineSharesView(title      : "Titre",
                                                  family     : family,
                                                  patrimoine : patrimoine,
                                                  year       : Int(uiState.patrimoineViewState.evalDate))
            }
            HStack {
                PatrimoineCategorySharesView(title      : "ACTIFS\nPAR\nCATÉGORIE",
                                             patrimoine : patrimoine,
                                             year       : Int(uiState.patrimoineViewState.evalDate))
                FamilyMembersPatrimoineSharesView(title      : "Titre",
                                                  family     : family,
                                                  patrimoine : patrimoine,
                                                  year       : Int(uiState.patrimoineViewState.evalDate))
            }
        }
    }
}

struct FamilyMembersPatrimoineSharesView : View {
    var title       : String
    var family      : Family
    var patrimoine  : Patrimoin
    var year        : Int
    @State private var evaluationContext: EvaluationContext = .patrimoine
    
    var body: some View {
        VStack {
            HStack {
                CasePicker(pickedCase: $evaluationContext, label: "Context d'évaluation:")
                    .pickerStyle(MenuPickerStyle())
                Text(evaluationContext.displayString)
            }
            
            PieChartTemplateView(title : title,
                                 data  : data)
        }
        .padding(.top).border(Color.white)
    }
    
    var data : [(label: String, value: Double)] {
        let membersName = family.adultsName
        let dataEntries: [(label: String, value: Double)] =
            membersName.map { memberName in
                let memberActifNet = patrimoine.ownedValue(by                : memberName,
                                                           atEndOf           : year,
                                                           evaluationContext : evaluationContext)
                let adultPrenom = family.member(withName: memberName)!.name.givenName!
                return (label: adultPrenom, value: memberActifNet)
            }
        return dataEntries
    }
}

struct PatrimoineCategorySharesView : View {
    var title      : String
    var patrimoine : Patrimoin
    var year       : Int
    
    var body: some View {
        PieChartTemplateView(title : title,
                             data  : data)
            .padding(.top).border(Color.white)
    }
    
    var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()
        
        let realEstates = (label: "Immobilier Physique",
                           value: patrimoine.assets.realEstates.value(atEndOf: year))
        dataEntries.append(realEstates)
        
        let scpi = (label: "Immobilier SCPI",
                    value: patrimoine.assets.scpis.value(atEndOf: year) +
                        patrimoine.assets.sci.scpis.value(atEndOf: year))
        dataEntries.append(scpi)
        
        let periodicInvests = (label: "Investis. Périodiques",
                               value: patrimoine.assets.periodicInvests.value(atEndOf: year))
        dataEntries.append(periodicInvests)

        let freeInvests = (label: "Investis. Libres",
                           value: patrimoine.assets.freeInvests.value(atEndOf: year))
        dataEntries.append(freeInvests)

        return dataEntries
    }
}

struct PatrimoineSummaryChartView_Previews: PreviewProvider {
    static var previews: some View {
        loadTestFilesFromBundle()
        return PatrimoineSummaryChartView()
            .preferredColorScheme(.dark)
            .environmentObject(dataStoreTest)
            .environmentObject(familyTest)
            .environmentObject(patrimoineTest)
            .environmentObject(uiStateTest)
    }
}
