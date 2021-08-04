//
//  RetirementDetailView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 25/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import RetirementModel
import ModelEnvironment

// MARK: - Retirement View Model

class RetirementViewModel: ObservableObject {
    
    struct General {
        var sam              : Double = 0
        var tauxDePension    : Double = 0
        var majorationEnfant : Double = 0
        var dureeDeReference : Int    = 0
        var dureeAssurance   : Int    = 0
        var dateTauxPlein    : Date?
        var ageTauxPlein     : DateComponents?
        var nbTrimestreDecote: Int    = 0
        var pensionBrute     : Double = 0
        var pensionNette     : Double = 0
        
        mutating func update(with model : Model,
                             for member : Person) {
            let adult = member as! Adult
            guard let (tauxDePension,
                       majorationEnfant,
                       dureeDeReference,
                       dureeAssurancePlafonne,
                       dureeAssuranceDeplafonne,
                       pensionBrute,
                       pensionNette) =
                    model.retirementModel.regimeGeneral.pension(
                        birthDate                : adult.birthDate,
                        dateOfRetirement         : adult.dateOfRetirement,
                        dateOfEndOfUnemployAlloc : adult.dateOfEndOfUnemployementAllocation(using: model),
                        dateOfPensionLiquid      : adult.dateOfPensionLiquid,
                        lastKnownSituation       : adult.lastKnownPensionSituation,
                        nbEnfant                 : 3) else {
                return
            }
            guard let nbTrimestreDecote =
                    model.retirementModel.regimeGeneral.nbTrimestreSurDecote(
                        birthDate           : adult.birthDate,
                        dureeAssurance      : dureeAssuranceDeplafonne,
                        dureeDeReference    : dureeDeReference,
                        dateOfPensionLiquid : adult.dateOfPensionLiquid) else {
                return
            }
            self.dateTauxPlein     =
                model.retirementModel.regimeGeneral.dateAgeTauxPlein(
                    birthDate          : member.birthDate,
                    lastKnownSituation : (member as! Adult).lastKnownPensionSituation)
            if dateTauxPlein != nil {
                self.ageTauxPlein  = member.age(atDate: dateTauxPlein!)
            }
            self.sam               = (member as! Adult).lastKnownPensionSituation.sam
            self.majorationEnfant  = majorationEnfant / 100
            self.tauxDePension     = tauxDePension / 100
            self.nbTrimestreDecote = nbTrimestreDecote
            self.dureeDeReference  = dureeDeReference
            self.dureeAssurance    = dureeAssurancePlafonne
            self.pensionBrute      = pensionBrute
            self.pensionNette      = pensionNette
        }
    }
    
    struct Agirc {
        var projectedNbOfPoints : Int    = 0
        var valeurDuPoint       : Double = 0
        var coefMinoration      : Double = 0
        var majorationEnfant    : Double = 0
        var pensionBrute        : Double = 0
        var pensionNette        : Double = 0
        
        mutating func update(with model : Model,
                             for member : Person) {
            let adult = member as! Adult
            guard let pension =
                    model.retirementModel.regimeAgirc.pension(
                        lastAgircKnownSituation : adult.lastKnownAgircPensionSituation,
                        birthDate               : adult.birthDate,
                        lastKnownSituation      : adult.lastKnownPensionSituation,
                        dateOfRetirement        : adult.dateOfRetirement,
                        dateOfEndOfUnemployAlloc: adult.dateOfEndOfUnemployementAllocation(using: model),
                        dateOfPensionLiquid     : adult.dateOfPensionLiquid,
                        nbEnfantNe              : adult.nbOfChildren(),
                        nbEnfantACharge         : adult.nbOfFiscalChildren(during: adult.dateOfPensionLiquid.year)) else { return }
            self.projectedNbOfPoints = pension.projectedNbOfPoints
            self.valeurDuPoint       = model.retirementModel.regimeAgirc.valeurDuPoint
            self.coefMinoration      = pension.coefMinoration
            self.majorationEnfant    = pension.majorationPourEnfant
            self.pensionBrute        = pension.pensionBrute
            self.pensionNette        = pension.pensionNette
        }
    }
    // régime général
    @Published var general = General()
    // régime complémentaire
    @Published var agirc = Agirc()
    
    func update(with model : Model,
                for member : Person) {
        self.general.update(with: model, for: member)
        self.agirc.update(with: model, for: member)
    }
}

// MARK: - RetirementDetail View

struct RetirementDetailView: View {

    // MARK: - Properties
    
    @EnvironmentObject private var model  : Model
    @EnvironmentObject private var member : Person
    @StateObject private var viewModel    = RetirementViewModel()
    
    var body: some View {
        let adult = member as! Adult
        return Form {
            AmountView(label: "Pension annuelle brute", amount: viewModel.general.pensionBrute + viewModel.agirc.pensionBrute)
            AmountView(label: "Pension annuelle nette", amount: viewModel.general.pensionNette + viewModel.agirc.pensionNette, weight: .bold)
            Section(header: Text("REGIME GENERAL (liquidation le: \(adult.displayDateOfPensionLiquid) à \(generalLiquidAge(adult)))").font(.subheadline)) {
                AmountView(label: "Salaire annuel moyen", amount: viewModel.general.sam, comment: "SAM")
                AgeDateView(label: "Date du taux plein")
                IntegerView(label: viewModel.general.nbTrimestreDecote >= 0 ? "Nombre de trimestres de surcote" : "Nombre de trimestres de décote",
                            integer: viewModel.general.nbTrimestreDecote)
                PercentView(label: "Taux de réversion", percent: viewModel.general.tauxDePension, comment: "Trev")
                AmountView(label: "Majoration pour enfants", amount: viewModel.general.majorationEnfant, comment: "Menf")
                IntegerView(label: "Durée d'assurance (trimestres)", integer: viewModel.general.dureeAssurance, comment: "Da")
                IntegerView(label: "Durée de référence (trimestres)", integer: viewModel.general.dureeDeReference, comment: "Dr")
                AmountView(label: "Pension annuelle brute", amount: viewModel.general.pensionBrute, comment: "Brut = SAM x Trev x (1 + Menf) x Da/Dr")
                AmountView(label: "Pension annuelle nette", amount: viewModel.general.pensionNette, weight: .bold, comment: "Net = Brut - Prélev sociaux")
            }
            Section(header: Text("REGIME COMPLEMENTAIRE (liquidation le: \(adult.displayDateOfAgircPensionLiquid) à \(agircLiquidAge(adult)))").font(.subheadline)) {
                IntegerView(label: "Nombre de points", integer: viewModel.agirc.projectedNbOfPoints, comment: "Npt")
                AmountView(label: "Valeur de 1000 points", amount: viewModel.agirc.valeurDuPoint * 1000, comment: "Vpt")
                PercentView(label: "Coeficient de minoration", percent: viewModel.agirc.coefMinoration, comment: "Cmin")
                PercentView(label: "Majoration pour enfants", percent: viewModel.agirc.majorationEnfant, comment: "Menf")
                AmountView(label: "Pension annuelle brute", amount: viewModel.agirc.pensionBrute, comment: "Brut = Npt x Vpt x Cmin + Menf")
                AmountView(label: "Pension annuelle nette", amount: viewModel.agirc.pensionNette, weight: .bold, comment: "Net = Brut - Prélev sociaux")
            }
        }
        .navigationTitle("Retraite de \(member.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func generalLiquidAge(_ adult: Adult) -> String {
        if let year = adult.ageOfPensionLiquidComp.year, let month = adult.ageOfPensionLiquidComp.month {
            return "\(year) ans \(month) mois"
        } else {
            return "`nil`"
        }
    }
    
    func agircLiquidAge(_ adult: Adult) -> String {
        if let year = adult.ageOfAgircPensionLiquidComp.year, let month = adult.ageOfAgircPensionLiquidComp.month {
            return "\(year) ans \(month) mois"
        } else {
            return "`nil`"
        }
    }
    
    func AgeDateView(label: String) -> some View {
        return HStack {
            Text(label)
            Spacer()
            if viewModel.general.dateTauxPlein == nil || viewModel.general.ageTauxPlein == nil {
                EmptyView()
            } else {
                Text(mediumDateFormatter.string(from: viewModel.general.dateTauxPlein!) +
                        " à l'age de \(viewModel.general.ageTauxPlein!.year!) ans \(viewModel.general.ageTauxPlein!.month!) mois")
            }
        }
    }
    
    func onAppear() {
        viewModel.update(with: model, for: member)
    }
}

struct RetirementDetailView_Previews: PreviewProvider {
    static var family  = Family()
    static var model   = Model(fromBundle: Bundle.main)

    static var previews: some View {
        let aMember = family.members.items.first!
        
        return RetirementDetailView()
            .environmentObject(model)
            .environmentObject(aMember)
        
    }
}
