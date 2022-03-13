//
//  UnemployementDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import PersonModel
import FamilyModel
import HelpersView

struct UnemployementDetailView: View {

    // MARK: - View Model
    
    struct ViewModel {
        var allocationReducedBrut : Double = 0
        var allocationReducedNet  : Double = 0
        var allocationBonnified   : Bool   = false
        var allocationBrut        : Double = 0
        var allocationNet         : Double = 0
        var totalAllocationNet    : Double = 0
        var durationInMonth       : Int    = 0
        var percentReduc          : Double = 0
        var differe               : Int?
        var afterMonth            : Int?
        var compensationLegal     : Double = 0
        var compensationConvention: Double = 0
        var compensationBrut      : Double = 0
        var compensationNet       : Double = 0
        var compensationTaxable   : Double = 0
        var compensationNbMonth   : Double = 0
        
        // MARK: - Initializers
        
        init() {
        }
        
        init(from adult  : Adult,
             using model : Model) {
            differe                                       = adult.unemployementAllocationDiffere(using: model)
            durationInMonth                               = adult.unemployementAllocationDuration(using: model)!
            (allocationBrut, allocationNet)               = adult.unemployementAllocation(using: model)!
            (percentReduc, afterMonth)                    = adult.unemployementAllocationReduction(using: model)!
            (compensationNbMonth, compensationBrut,
             compensationNet, compensationTaxable)        = adult.layoffCompensation(using: model)!
            compensationLegal                             = adult.layoffCompensationBrutLegal(using: model)!
            compensationConvention                        = adult.layoffCompensationBrutConvention(using: model)!
            allocationBonnified                           = (adult.layoffCompensationBonified != nil)
            (allocationReducedBrut, allocationReducedNet) = adult.unemployementReducedAllocation(using: model)!
            totalAllocationNet                            = adult.unemployementTotalAllocation(using: model)!.net
        }
    }
    
    // MARK: - Properties
    
    @EnvironmentObject private var model  : Model
    @EnvironmentObject private var member : Person
    @State var viewModel = ViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Indemnité de licenciement").font(.subheadline)) {
                if viewModel.allocationBonnified {
                    AmountView(label: "Montant brut légal", amount: viewModel.compensationLegal).foregroundColor(.gray)
                    AmountView(label: "Montant brut conventionnel", amount: viewModel.compensationConvention).foregroundColor(.gray)
                    AmountView(label: "Montant réel brut (avec bonus supra-convention)", amount: viewModel.compensationBrut)
                } else {
                    HStack {
                        IntegerView(label: "Equivalente à", integer: Int(viewModel.compensationNbMonth.rounded()))
                        Text("mois")
                    }
                    AmountView(label: "Montant brut légal", amount: viewModel.compensationLegal).foregroundColor(.gray)
                    AmountView(label: "Montant brut conventionnel", amount: viewModel.compensationBrut)
                }
                AmountView(label: "Montant net", amount: viewModel.compensationNet, weight: .bold)
                AmountView(label: "Montant imposable", amount: viewModel.compensationTaxable)
            }
            Section(header: Text("Allocation chômage").font(.subheadline)) {
                if let differe = viewModel.differe {
                    HStack {
                        IntegerView(label: "Différé spécifique (car indemn. supralégale)", integer: differe)
                        Text("jour")
                    }
                }
                HStack {
                    IntegerView(label: "Durée d'allocation", integer: viewModel.durationInMonth)
                    Text("mois")
                }
                AmountView(label: "Montant total perçu net (sur \(viewModel.durationInMonth) mois)", amount: viewModel.totalAllocationNet, weight: .bold)
            }
            Section(header: Text("Allocation chômage non réduite").font(.subheadline)) {
                AmountView(label: "Montant annuel brut", amount: viewModel.allocationBrut)
                AmountView(label: "Montant annuel net", amount: viewModel.allocationNet, weight: .bold)
            }
            if let afterMonth = viewModel.afterMonth {
                Section(header: Text("Allocation chômage réduite").font(.subheadline)) {
                    HStack {
                        IntegerView(label: "Réduction de l'allocation après", integer: afterMonth)
                        Text("mois")
                    }
                    PercentView(label: "Coefficient de réduction", percent: viewModel.percentReduc)
                    AmountView(label: "Montant annuel réduit brut", amount: viewModel.allocationReducedBrut)
                    AmountView(label: "Montant annuel réduit net", amount: viewModel.allocationReducedNet, weight: .bold)
                }
            }
        }
        .navigationTitle("Allocation chômage de \(member.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func onAppear() {
        let adult = member as! Adult
        viewModel = ViewModel(from: adult, using: model)
    }
}

struct UnemployementDetailView_Previews: PreviewProvider {
    static var family = Family()
    static var model  = Model(fromBundle : Bundle.main)

    static var previews: some View {
        let aMember = family.members.items.first!
        
        return UnemployementDetailView()
            .environmentObject(model)
            .environmentObject(aMember)
    }
}
