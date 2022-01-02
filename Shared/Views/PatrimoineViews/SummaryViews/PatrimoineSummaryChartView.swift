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
    static let tous = "Tous"
    @EnvironmentObject private var family     : Family
    @EnvironmentObject private var patrimoine : Patrimoin
    @EnvironmentObject private var uiState    : UIState
    @State private var evaluationContext      : EvaluationContext = .patrimoine
    @State private var selectedAdult          : String            = tous
    
    var body: some View {
        VStack {
            HStack {
                FamilyMembersPatrimoineSharesView(family            : family,
                                                  patrimoine        : patrimoine,
                                                  year              : Int(uiState.patrimoineViewState.evalDate),
                                                  evaluationContext : $evaluationContext)
                PatrimoineCategorySharesView(family            : family,
                                             patrimoine        : patrimoine,
                                             year              : Int(uiState.patrimoineViewState.evalDate),
                                             evaluationContext : evaluationContext,
                                             selectedAdult     : $selectedAdult)
            }
            HStack {
                PatrimoineSingleCategoryView(family            : family,
                                             patrimoine        : patrimoine,
                                             year              : Int(uiState.patrimoineViewState.evalDate),
                                             evaluationContext : evaluationContext,
                                             selectedAdult     : selectedAdult)
            }
        }
    }
}

struct FamilyMembersPatrimoineSharesView : View {
    var family      : Family
    var patrimoine  : Patrimoin
    var year        : Int
    @Binding var evaluationContext: EvaluationContext
    
    var body: some View {
        VStack {
            HStack {
                CasePicker(pickedCase: $evaluationContext, label: "Context d'évaluation:")
                    .pickerStyle(MenuPickerStyle())
                Text(evaluationContext.displayString)
            }
            
            PieChartTemplateView(chartDescription   : nil,
                                 centerText         : "REPARTITION\nDU\nPATRIMOINE\nNET DES\nADULTES",
                                 descriptionEnabled : true,
                                 legendEnabled      : false,
                                 data               : data)
        }
        .padding(.top).border(Color.white)
    }
    
    /// Données à afficher sur le graphique
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
    var family                 : Family
    var patrimoine             : Patrimoin
    var year                   : Int
    var evaluationContext      : EvaluationContext
    @Binding var selectedAdult : String
    private static let immobilier             = "Immobilier"
    private static let scpi                   = "SCPI"
    private static let freeInvest             = "Invest. Libres"
    private static let perdiodInvest          = "Invest. Périodiques"
    @State private var menuItems = [PatrimoineSummaryChartView.tous]
    
    var body: some View {
        VStack {
            HStack {
                Text("\(evaluationContext.displayString)")
                Spacer()
                Picker("Pour:", selection: $selectedAdult) {
                    ForEach(menuItems, id: \.self) { name in
                        Text(name)
                    }
                }.pickerStyle(MenuPickerStyle())
                Text(selectedAdult)
            }.padding(.horizontal)
            
            PieChartTemplateView(chartDescription   : nil,
                                 centerText         : "ACTIFS\nPAR\nCATÉGORIE",
                                 descriptionEnabled : true,
                                 legendEnabled      : false,
                                 data               : data)
        }
        .padding(.top).border(Color.white)
        .onAppear(perform: buildMenu)
    }
    
    var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()
        
        if selectedAdult == PatrimoineSummaryChartView.tous {
            var realEstatesTotal     = 0.0
            var scpisTotal           = 0.0
            var periodicInvestsTotal = 0.0
            var freeInvestsTotal     = 0.0
            
            family.adultsName.forEach { name in
                realEstatesTotal +=
                    patrimoine.assets.realEstates.ownedValue(by: name,
                                                             atEndOf: year,
                                                             evaluationContext: evaluationContext)
                scpisTotal +=
                    patrimoine.assets.scpis.ownedValue(by: name,
                                                       atEndOf: year,
                                                       evaluationContext: evaluationContext) +
                    patrimoine.assets.sci.scpis.ownedValue(by: name,
                                                           atEndOf: year,
                                                           evaluationContext: evaluationContext)
                periodicInvestsTotal +=
                    patrimoine.assets.periodicInvests.ownedValue(by: name,
                                                                 atEndOf: year,
                                                                 evaluationContext: evaluationContext)
                freeInvestsTotal +=
                    patrimoine.assets.freeInvests.ownedValue(by: name,
                                                             atEndOf: year,
                                                             evaluationContext: evaluationContext)
            }
            if realEstatesTotal != 0 {
                let realEstates = (label: PatrimoineCategorySharesView.immobilier,
                                   value: realEstatesTotal)
                dataEntries.append(realEstates)
            }
            
            if scpisTotal != 0 {
                let scpis = (label: PatrimoineCategorySharesView.scpi,
                             value: scpisTotal)
                dataEntries.append(scpis)
            }
            
            if periodicInvestsTotal != 0 {
                let periodicInvests = (label: PatrimoineCategorySharesView.perdiodInvest,
                                       value: periodicInvestsTotal)
                dataEntries.append(periodicInvests)
            }
            
            if freeInvestsTotal != 0 {
                let freeInvests = (label: PatrimoineCategorySharesView.freeInvest,
                                   value: freeInvestsTotal)
                dataEntries.append(freeInvests)
            }
            
        } else {
            let realEstates = (label: PatrimoineCategorySharesView.immobilier,
                               value: patrimoine.assets.realEstates.ownedValue(by: selectedAdult,
                                                                               atEndOf: year,
                                                                               evaluationContext: evaluationContext))
            if realEstates.value != 0 {
                dataEntries.append(realEstates)
            }
            
            let scpis = (label: PatrimoineCategorySharesView.scpi,
                         value: patrimoine.assets.scpis.ownedValue(by: selectedAdult,
                                                                   atEndOf: year,
                                                                   evaluationContext: evaluationContext) +
                            patrimoine.assets.sci.scpis.ownedValue(by: selectedAdult,
                                                                   atEndOf: year,
                                                                   evaluationContext: evaluationContext))
            if scpis.value != 0 {
                dataEntries.append(scpis)
            }
            
            let periodicInvests = (label: PatrimoineCategorySharesView.perdiodInvest,
                                   value: patrimoine.assets.periodicInvests.ownedValue(by: selectedAdult,
                                                                                       atEndOf: year,
                                                                                       evaluationContext: evaluationContext))
            if periodicInvests.value != 0 {
                dataEntries.append(periodicInvests)
            }
            
            let freeInvests = (label: PatrimoineCategorySharesView.freeInvest,
                               value: patrimoine.assets.freeInvests.ownedValue(by: selectedAdult,
                                                                               atEndOf: year,
                                                                               evaluationContext: evaluationContext))
            if freeInvests.value != 0 {
                dataEntries.append(freeInvests)
            }
        }
        
        return dataEntries
    }
    
    func buildMenu() {
        let adultsName = family.adultsName
        menuItems += adultsName
    }
}

/// Catégories d'actifs
enum PieChartAssetsCategory: String, PickableEnumP, Codable {
    case periodicInvests = "Invest. périodique"
    case freeInvests     = "Invest. libre"
    case realEstates     = "Immobilier"
    case scpis           = "SCPI"
    
    // properties
    
    public var pickerString: String {
        return self.rawValue
    }
}

struct PatrimoineSingleCategoryView : View {
    var family            : Family
    var patrimoine        : Patrimoin
    var year              : Int
    var evaluationContext : EvaluationContext
    var selectedAdult     : String
    @State private var selectedCategory: PieChartAssetsCategory = .freeInvests
    
    var body: some View {
        HStack {
            PieChartTemplateView(chartDescription   : nil,
                                 centerText         : "REPARTITION\nDANS UNE\nCATÉGORIE\nD'ACTIF",
                                 descriptionEnabled : true,
                                 legendEnabled      : true,
                                 legendPosition     : .left,
                                 smallLegend        : false,
                                 data               : data)
            
            VStack {
                VStack {
                    Text("\(evaluationContext.displayString)")
                        .padding(.top)
                    Text("Pour: \(selectedAdult)")
                        .padding(.top)
                    HStack {
                        CasePicker(pickedCase: $selectedCategory, label: "Categorie:")
                            .pickerStyle(MenuPickerStyle())
                        Text(selectedCategory.displayString)
                    }.padding(.vertical)
                }
                .padding(.horizontal).border(Color.secondary)
                .padding()
                Spacer()
            }
        }.border(Color.white)
        
    }
    
    /// Données à afficher sur le graphique
    var data : [(label: String, value: Double)] {
        var dataEntries = [(label: String, value: Double)]()
        
        switch selectedCategory {
            case .periodicInvests:
                patrimoine.assets.periodicInvests.items.sorted {
                    ($0.type.rawValue < $1.type.rawValue) ||
                        (($0.type.rawValue == $1.type.rawValue) &&
                            $0.ownedValue(by                : selectedAdult,
                                          atEndOf           : year,
                                          evaluationContext : evaluationContext) >
                            $1.ownedValue(by                : selectedAdult,
                                          atEndOf           : year,
                                          evaluationContext : evaluationContext))
                }.forEach { item in
                    var value = 0.0
                    if selectedAdult == PatrimoineSummaryChartView.tous {
                        family.adultsName.forEach { name in
                            value += item.ownedValue(by                : name,
                                                     atEndOf           : year,
                                                     evaluationContext : evaluationContext)
                        }
                        
                    } else {
                        value = item.ownedValue(by                : selectedAdult,
                                                atEndOf           : year,
                                                evaluationContext : evaluationContext)
                    }
                    if value != 0 {
                        dataEntries.append((label: item.name, value: value))
                    }
                }
                
            case .freeInvests:
                patrimoine.assets.freeInvests.items.sorted {
                    ($0.type.rawValue < $1.type.rawValue) ||
                        (($0.type.rawValue == $1.type.rawValue) &&
                            $0.ownedValue(by                : selectedAdult,
                                          atEndOf           : year,
                                          evaluationContext : evaluationContext) >
                            $1.ownedValue(by                : selectedAdult,
                                          atEndOf           : year,
                                          evaluationContext : evaluationContext))
                }.forEach { item in
                    var value = 0.0
                    if selectedAdult == PatrimoineSummaryChartView.tous {
                        family.adultsName.forEach { name in
                            value += item.ownedValue(by                : name,
                                                     atEndOf           : year,
                                                     evaluationContext : evaluationContext)
                        }
                        
                    } else {
                        value = item.ownedValue(by                : selectedAdult,
                                                atEndOf           : year,
                                                evaluationContext : evaluationContext)
                    }
                    if value != 0 {
                        dataEntries.append((label: item.name, value: value))
                    }
                }
                return dataEntries
                
            case .realEstates:
                patrimoine.assets.realEstates.items.forEach { item in
                    var value = 0.0
                    if selectedAdult == PatrimoineSummaryChartView.tous {
                        family.adultsName.forEach { name in
                            value += item.ownedValue(by                : name,
                                                     atEndOf           : year,
                                                     evaluationContext : evaluationContext)
                        }
                    } else {
                        value = item.ownedValue(by                : selectedAdult,
                                                atEndOf           : year,
                                                evaluationContext : evaluationContext)
                    }
                    if value != 0 {
                        dataEntries.append((label: item.name, value: value))
                    }
                }
                
            case .scpis:
                patrimoine.assets.scpis.items.forEach { item in
                    var value = 0.0
                    if selectedAdult == PatrimoineSummaryChartView.tous {
                        family.adultsName.forEach { name in
                            value += item.ownedValue(by                : name,
                                                     atEndOf           : year,
                                                     evaluationContext : evaluationContext)
                        }
                    } else {
                        value = item.ownedValue(by                : selectedAdult,
                                                atEndOf           : year,
                                                evaluationContext : evaluationContext)
                    }
                    if value != 0 {
                        dataEntries.append((label: item.name, value: value))
                    }
                }
                patrimoine.assets.sci.scpis.items.forEach { item in
                    var value = 0.0
                    if selectedAdult == PatrimoineSummaryChartView.tous {
                        family.adultsName.forEach { name in
                            value += item.ownedValue(by                : name,
                                                     atEndOf           : year,
                                                     evaluationContext : evaluationContext)
                        }
                    } else {
                        value = item.ownedValue(by                : selectedAdult,
                                                atEndOf           : year,
                                                evaluationContext : evaluationContext)
                    }
                    if value != 0 {
                        dataEntries.append((label: "SCI_" + item.name, value: value))
                    }
                }
        }
        
        return dataEntries.sortedReversed(by: \.value)
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
