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

struct RetirementDetailView: View {
    
    // MARK: - View Model
    
    class ViewModel: ObservableObject {
        
        struct General { // swiftlint:disable:this nesting
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
        }
        
        struct Agirc { // swiftlint:disable:this nesting
            var projectedNbOfPoints : Int    = 0
            var valeurDuPoint       : Double = 0
            var coefMinoration      : Double = 0
            var majorationEnfant    : Double = 0
            var pensionBrute        : Double = 0
            var pensionNette        : Double = 0
        }
        // régime général
        @Published var general = General()
        // régime complémentaire
        @Published var agirc = Agirc()
    }
    
    // MARK: - Properties
    
    @EnvironmentObject var member: Person
    @ObservedObject var viewModel = ViewModel()
    
    var body: some View {
        Form {
            AmountView(label: "Pension annuelle brute", amount: viewModel.general.pensionBrute + viewModel.agirc.pensionBrute)
            AmountView(label: "Pension annuelle nette", amount: viewModel.general.pensionNette + viewModel.agirc.pensionNette, weight: .bold)
            Section(header: Text("REGIME GENERAL").font(.subheadline)) {
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
            Section(header: Text("REGIME COMPLEMENTAIRE").font(.subheadline)) {
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
        // régime général
        let adult = member as! Adult
        guard let (tauxDePension,
                   majorationEnfant,
                   dureeDeReference,
                   dureeAssurancePlafonne,
                   dureeAssuranceDeplafonne,
                   pensionBrute,
                   pensionNette) =
                Retirement.model.regimeGeneral.pension(
                    birthDate                : adult.birthDate,
                    dateOfRetirement         : adult.dateOfRetirement,
                    dateOfEndOfUnemployAlloc : adult.dateOfEndOfUnemployementAllocation,
                    dateOfPensionLiquid      : adult.dateOfPensionLiquid,
                    lastKnownSituation       : adult.lastKnownPensionSituation,
                    nbEnfant                 : 3) else {
            return
        }
        guard let nbTrimestreDecote =
                Retirement.model.regimeGeneral.nbTrimestreSurDecote(
                    birthDate           : adult.birthDate,
                    dureeAssurance      : dureeAssuranceDeplafonne,
                    dureeDeReference    : dureeDeReference,
                    dateOfPensionLiquid : adult.dateOfPensionLiquid) else {
            return
        }
        viewModel.general.dateTauxPlein     =
            Retirement.model.regimeGeneral.dateAgeTauxPlein(birthDate          : member.birthDate,
                                                            lastKnownSituation : (member as! Adult).lastKnownPensionSituation)
        if viewModel.general.dateTauxPlein != nil {
            viewModel.general.ageTauxPlein  = member.age(atDate: viewModel.general.dateTauxPlein!)
        }
        viewModel.general.sam               = (member as! Adult).lastKnownPensionSituation.sam
        viewModel.general.majorationEnfant  = majorationEnfant / 100
        viewModel.general.tauxDePension     = tauxDePension / 100
        viewModel.general.nbTrimestreDecote = nbTrimestreDecote
        viewModel.general.dureeDeReference  = dureeDeReference
        viewModel.general.dureeAssurance    = dureeAssurancePlafonne
        viewModel.general.pensionBrute      = pensionBrute
        viewModel.general.pensionNette      = pensionNette
        
        // régime complémentaire
        guard let pension =
                Retirement.model.regimeAgirc.pension(
                    lastAgircKnownSituation : adult.lastKnownAgircPensionSituation,
                    birthDate               : adult.birthDate,
                    lastKnownSituation      : adult.lastKnownPensionSituation,
                    dateOfRetirement        : adult.dateOfRetirement,
                    dateOfEndOfUnemployAlloc: adult.dateOfEndOfUnemployementAllocation,
                    dateOfPensionLiquid     : adult.dateOfPensionLiquid,
                    nbEnfantNe              : adult.nbOfChildren(),
                    nbEnfantACharge         : adult.nbOfFiscalChildren(during: adult.dateOfPensionLiquid.year)) else { return }
        viewModel.agirc.projectedNbOfPoints = pension.projectedNbOfPoints
        viewModel.agirc.valeurDuPoint       = Retirement.model.regimeAgirc.valeurDuPoint
        viewModel.agirc.coefMinoration      = pension.coefMinoration
        viewModel.agirc.majorationEnfant    = pension.majorationPourEnfant
        viewModel.agirc.pensionBrute        = pension.pensionBrute
        viewModel.agirc.pensionNette        = pension.pensionNette
    }
}

struct RetirementDetailView_Previews: PreviewProvider {
    static var family  = Family()
    
    static var previews: some View {
        let aMember = family.members.first!
        
        return RetirementDetailView().environmentObject(aMember)
        
    }
}
