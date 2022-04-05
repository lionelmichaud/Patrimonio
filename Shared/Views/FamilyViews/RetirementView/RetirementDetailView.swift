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
import PersonModel
import FamilyModel
import HelpersView

// MARK: - Retirement View Model

final class RetirementViewModel: ObservableObject {
    
    struct General {
        var dateLiquidation  : Date?
        var ageLiquidation   : String = ""
        var sam              : Double = 0
        var tauxDePension    : Double = 0
        var majorationEnfant : Double = 0
        var nbEnfantNe       : Int    = 0
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
                        nbEnfantNe               : adult.nbOfBornChildren()) else {
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
            self.dateLiquidation   = (member as! Adult).dateOfPensionLiquid
            self.ageLiquidation    = generalLiquidAge(adult)
            self.sam               = (member as! Adult).lastKnownPensionSituation.sam
            self.majorationEnfant  = majorationEnfant / 100
            self.nbEnfantNe        = adult.nbOfBornChildren()
            self.tauxDePension     = tauxDePension / 100
            self.nbTrimestreDecote = nbTrimestreDecote
            self.dureeDeReference  = dureeDeReference
            self.dureeAssurance    = dureeAssurancePlafonne
            self.pensionBrute      = pensionBrute
            self.pensionNette      = pensionNette
        }
    }
    
    struct Agirc {
        var dateLiquidation     : Date?
        var ageLiquidation      : String = ""
        var projectedNbOfPoints : Int    = 0
        var valeurDuPoint       : Double = 0
        var coefMinoration      : Double = 0
        var majorationEnfant    : Double = 0
        var nbEnfantNe          : Int    = 0
        var nbEnfantACharge     : Int    = 0
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
                        nbEnfantNe              : adult.nbOfBornChildren(),
                        nbEnfantACharge         : adult.nbOfFiscalChildren(during: adult.dateOfPensionLiquid.year)) else { return }
            self.dateLiquidation     = (member as! Adult).dateOfAgircPensionLiquid
            self.ageLiquidation      = agircLiquidAge(adult)
            self.projectedNbOfPoints = pension.projectedNbOfPoints
            self.valeurDuPoint       = model.retirementModel.regimeAgirc.valeurDuPoint
            self.coefMinoration      = pension.coefMinoration
            self.nbEnfantNe          = adult.nbOfBornChildren()
            self.nbEnfantACharge     = adult.nbOfFiscalChildren(during: adult.dateOfPensionLiquid.year)
            self.majorationEnfant    = pension.majorationPourEnfant
            self.pensionBrute        = pension.pensionBrute
            self.pensionNette        = pension.pensionNette
        }
    }
    // régime général
    @Published var general = General()
    // régime complémentaire
    @Published var agirc = Agirc()
    
    static func agircLiquidAge(_ adult: Adult) -> String {
        if let year = adult.ageOfAgircPensionLiquidComp.year, let month = adult.ageOfAgircPensionLiquidComp.month {
            return "\(year) ans \(month) mois"
        } else {
            return "`nil`"
        }
    }
    
    static func generalLiquidAge(_ adult: Adult) -> String {
        if let year = adult.ageOfPensionLiquidComp.year, let month = adult.ageOfPensionLiquidComp.month {
            return "\(year) ans \(month) mois"
        } else {
            return "`nil`"
        }
    }
    
    func update(with model : Model,
                for member : Person) {
        self.general.update(with: model, for: member)
        self.agirc.update(with: model, for: member)
    }
}

// MARK: - RetirementDetailView

struct RetirementDetailView: View {

    // MARK: - Properties
    
    @EnvironmentObject private var model  : Model
    @EnvironmentObject private var member : Person
    @StateObject private var viewModel    = RetirementViewModel()
    
    var body: some View {
        Form {
            // Cumul tous régimes
            AmountView(label   : "Pension annuelle brute (non dévaluée)",
                       amount  : viewModel.general.pensionBrute + viewModel.agirc.pensionBrute,
                       comment : "General : \(viewModel.general.ageLiquidation) - AGIRC : \(viewModel.agirc.ageLiquidation)")
            AmountView(label   : "Pension annuelle nette (non dévaluée)",
                       amount  : viewModel.general.pensionNette + viewModel.agirc.pensionNette,
                       weight  : .bold,
                       comment : "General : \(viewModel.general.ageLiquidation) - AGIRC : \(viewModel.agirc.ageLiquidation)")

            // Régime Général
            RetirementGeneralSectionView()
                .environmentObject(viewModel)
            
            // Régime Complémentaire
            RetirementAgircSectionView()
                .environmentObject(viewModel)
        }
        .navigationTitle("Retraite de \(member.displayName)")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: onAppear)
    }
    
    // MARK: - Methods
    
    func onAppear() {
        viewModel.update(with: model, for: member)
    }
}

// MARK: - RetirementDetailView / General

struct RetirementGeneralSectionView: View {
    @EnvironmentObject private var viewModel: RetirementViewModel
    @State private var alertItem     : AlertItem?
    @State private var showingSheet  = false
    
    let str =
    """
    Les périodes de chômage indemnisé
     Cas général
      On comptera 1 trimestre par période de 50 jours indemnisés, dans la limite de 4 trimestres par an.
      Si vous avez cumulé travail à temps partiel et allocations chômage
      On comptera d'abord à combien de trimestres vous donnent droit les cotisations payées sur vos revenus d'activité. Si vous n'avez pas gagné suffisamment pour valider 4 trimestres cotisés, vous bénéficierez du complément en trimestres assimilé pour le chômage.
      Par exemple, si vous n'avez validé que 3 trimestres en travaillant à temps partiel et que vous perceviez un complément d'indemnisation, vous bénéficierez d'un 4e trimestre (assimilé) au titre du chômage indemnisé.
    """

    var HeaderView: some View {
        HStack {
            Text("REGIME GENERAL")
                .font(.headline)
            Button(action: { self.showingSheet = true },
                   label : { Image(systemName: "info.circle").imageScale(.large) })
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(viewModel.general.pensionBrute.€String)")
                Text("\(viewModel.general.pensionNette.€String)").bold()
            }
        }
        .alert(item: $alertItem, content: newAlert)
        .sheet(isPresented: $showingSheet) {
            ScrollView(.vertical, showsIndicators: true) {
                Text("Calcul du montant").bold().padding(.bottom)
                Image("calcul-montant-regime-general").resizable().aspectRatio(contentMode: .fit).padding(.bottom)
                
                Text("Coefficient de minoration / majoration").bold().padding(.bottom)
                Image("Pension de base - minoration").resizable().aspectRatio(contentMode: .fit)
                
                Text("Périodes de chômage").bold().padding(.bottom)
                Image("Chomage et retraite").resizable().aspectRatio(contentMode: .fit)
                Text("""
                Les périodes de chômage indemnisé
                 Cas général
                  - On comptera 1 trimestre par période de 50 jours indemnisés, dans la limite de 4 trimestres par an.
                  - Si vous avez cumulé travail à temps partiel et allocations chômage
                  - On comptera d'abord à combien de trimestres vous donnent droit les cotisations payées sur vos revenus d'activité. Si vous n'avez pas gagné suffisamment pour valider 4 trimestres cotisés, vous bénéficierez du complément en trimestres assimilé pour le chômage.
                  - Par exemple, si vous n'avez validé que 3 trimestres en travaillant à temps partiel et que vous perceviez un complément d'indemnisation, vous bénéficierez d'un 4e trimestre (assimilé) au titre du chômage indemnisé.

                Les périodes de chômage non indemnisé
                 La 1ère période de chômage non indemnisé
                  - Lors de la 1ère période de chômage non indemnisé dans une carrière, ne faisant pas suite à une période de chômage indemnisé, on peut valider des trimestres. On compte 1 trimestre par période de 50 jours de chômage, dans la limite de :
                  6 trimestres à partir du 1er juillet 2011.
                  - Les périodes suivantes
                   - Une condition s'ajoute : il faut que la période de chômage non indemnisé succède immédiatement à une période de chômage indemnisé. Les trimestres comptent alors de la même façon dans la limite d'1 an. Si vous avez plus de 55 ans ET que vous avez cotisé au moins 20 ans à la retraite, la limite est portée à 5 années.
                
                Règles particulières pour le chômage non indemnisé
                 - Il faut, de toute façon, avoir cotisé au régime général ou à la SSI avant la période de chômage pour valider des trimestres. Il n'y a pas de montant minimal, un simple job d'été suffit. Mais si vous cherchez du travail après vos études alors que vous n'avez jamais travaillé et cotisé, votre période de recherche ne comptera pas pour la retraite.
                 - La 1ère période de chômage d'1 an 1/2 peut être « continue » ou « discontinue ». C'est-à-dire que si vous avez repris une activité pendant cette période, rémunérée mais pas suffisamment longue pour vous ouvrir des droits au chômage indemnisé, cela n'interrompt pas la validation ; vos trimestres de chômage au-delà de cette période de travail pourront bien être validés.
                 - Pour les périodes suivantes, en revanche, le chômage non indemnisé doit être « continu » ; si vous retravaillez ne serait-ce qu'un jour, sans ouvrir de nouveaux droits au chômage, les périodes au-delà ne seront pas prises en compte.
                """)
            }.padding()
        }
    }
    
    var body: some View {
        DisclosureGroup(
            content: {
                HStack {
                    Text("Liquidation le ")
                    Spacer()
                    Text("\(viewModel.general.dateLiquidation.stringShortDate) à \(viewModel.general.ageLiquidation)")
                }
                AmountView(label: "Salaire annuel moyen",
                           amount: viewModel.general.sam, comment: "SAM")
                AgeDateView(label: "Date du taux plein")
                IntegerView(label: viewModel.general.nbTrimestreDecote >= 0 ? "Nombre de trimestres de surcote" : "Nombre de trimestres de décote",
                            integer: viewModel.general.nbTrimestreDecote)
                PercentNormView(label: "Taux de réversion",
                                percent: viewModel.general.tauxDePension, comment: "Trev")
                PercentNormView(label: "Majoration pour enfants nés (\(viewModel.general.nbEnfantNe))",
                                percent: viewModel.general.majorationEnfant, comment: "Menf")
                IntegerView(label: "Durée d'assurance (trimestres)",
                            integer: viewModel.general.dureeAssurance, comment: "Da")
                IntegerView(label: "Durée de référence (trimestres)",
                            integer: viewModel.general.dureeDeReference, comment: "Dr")
                AmountView(label: "Pension annuelle brute (non dévaluée)",
                           amount: viewModel.general.pensionBrute, comment: "Brut = SAM x Trev x (1 + Menf) x Da/Dr")
                AmountView(label: "Pension annuelle nette (non dévaluée)",
                           amount: viewModel.general.pensionNette, weight: .bold, comment: "Net = Brut - Prélev sociaux")
            },
            label: { HeaderView }
        )
    }
    
    func AgeDateView(label: String) -> some View {
        return HStack {
            Text(label)
            Spacer()
            if viewModel.general.dateTauxPlein == nil || viewModel.general.ageTauxPlein == nil {
                EmptyView()
            } else {
                Text(viewModel.general.dateTauxPlein!.stringMediumDate +
                        " à l'age de \(viewModel.general.ageTauxPlein!.year!) ans \(viewModel.general.ageTauxPlein!.month!) mois")
            }
        }
    }
}

// MARK: - RetirementDetailView / Agirc

struct RetirementAgircSectionView: View {
    @EnvironmentObject private var viewModel: RetirementViewModel
    @State private var alertItem     : AlertItem?
    @State private var showingSheet  = false
    
    var HeaderView: some View {
        HStack {
            Text("REGIME COMPLEMENTAIRE")
                .font(.headline)
            Button(action: { self.showingSheet = true },
                   label : { Image(systemName: "info.circle").imageScale(.large) })
            Spacer()
            VStack(alignment: .trailing) {
                Text("\(viewModel.agirc.pensionBrute.€String)")
                Text("\(viewModel.agirc.pensionNette.€String)").bold()
            }
        }
        .alert(item: $alertItem, content: newAlert)
        .sheet(isPresented: $showingSheet) {
            ScrollView(.vertical, showsIndicators: true) {
                Text("Age de départ à taux plein: Coefficient de solidarité").bold().padding(.bottom)
                Text("""
                Plusieurs situations se présentent:
                - le salarié demande sa retraite complémentaire à la date à laquelle il bénéficie du taux plein dans le régime de base. Il subira une minoration de 10 % pendant 3 ans du montant de sa retraite complémentaire, et au maximum jusqu’à l’âge de 67 ans.
                - le salarié demande sa retraite complémentaire 1 an après la date à laquelle il bénéficie du taux plein dans le régime de base. Il ne subira pas de coefficient de solidarité.
                - le salarié demande sa retraite complémentaire 2 ans après la date à laquelle il bénéficie du taux plein dans le régime de base. Il bénéficie alors d’un bonus et sa pension de retraite complémentaire est alors majorée pendant 1 an de 10 %.
                - s’il décale la liquidation de 3 ans, la majoration est de 20 %.
                - s’il décale la liquidation de 4 ans, la majoration atteindra 30 %.
                """)
                Image("agirc_coef").resizable().aspectRatio(contentMode: .fit).padding(.bottom)
                
                Text("Age de départ à taux minoré défintif").bold().padding(.bottom)
                Text("""
                Vous pouvez aussi obtenir votre retraite complémentaire sans que les conditions ci-dessus soient remplies, sous réserve que vous ayez au minimum 57 ans.
                Dans ce cas, le montant de votre retraite complémentaire sera diminué selon un coefficient de minoration, et cela de manière définitive.
                La minoration dépend de l'âge que vous avez atteint au moment du départ à la retraite.
                Si vous avez obtenu votre retraite de base à taux minoré et qu’il vous manque au minimum 20 trimestres pour bénéficier de la retraite de base à taux plein, la minoration appliquée est déterminée en fonction de votre âge ou du nombre de trimestres manquants.
                La solution la plus favorable pour vous sera choisie.
                """)
                Image("coef_mino_agirc").resizable().aspectRatio(contentMode: .fit).padding(.bottom)
                
                Text("Majoration pour enfant né ou élevé").bold().padding(.bottom)
                Image("Majoration pour enfant regime complementaire").resizable().aspectRatio(contentMode: .fit).padding(.bottom)

                Text("Périodes de chômage").bold().padding(.bottom)
                Text("""
                Droits à la retraite complémentaire et chômage:
                Les périodes de chômage comptent dans l’acquisition des droits à la retraite complémentaire. Comme c'est le cas dans le régime de base, seules les périodes de chômage indemnisé permettent à l'assuré d'acquérir des droits.
                - L’acquisition de droits à la retraite complémentaire en période de chômage est soumise à deux conditions.
                 - La période de chômage doit être succéder à une période pendant laquelle le salarié a acquis des droits à la retraite (périodes d’activité salariée, périodes d’incapacité de travail indemnisées…)
                 - L’assuré est indemnisé par Pôle emploi.

                Attribution des points AGIRC-ARRCO pendant les périodes de chômage:
                - Pour chaque jour indemnisé par Pôle emploi, l’assuré acquiert des droits à la retraite complémentaire sous la forme de points.
                - Les périodes de carence ou de différé d’indemnisation ne permettent plus l’acquisition des points de retraite complémentaire.
                - C’est Pôle emploi qui informe votre caisse de retraite des périodes qu’il indemnise. Votre caisse de retraite calcule vos points en fonction des informations transmises.
                """)
            }.padding()
        }
    }
    
    var body: some View {
        DisclosureGroup(
            content: {
                HStack {
                    Text("Liquidation le ")
                    Spacer()
                    Text("\(viewModel.agirc.dateLiquidation.stringShortDate) à \(viewModel.agirc.ageLiquidation)")
                }
                IntegerView(label   : "Nombre de points",
                            integer : viewModel.agirc.projectedNbOfPoints,
                            comment : "Npt")
                AmountView(label   : "Valeur du point",
                           amount  : viewModel.agirc.valeurDuPoint, digit  : 3,
                           comment : "Vpt")
                PercentNormView(label   : "Coeficient de minoration (en \(viewModel.agirc.dateLiquidation?.year ?? 0))",
                                percent : viewModel.agirc.coefMinoration,
                                comment : "Cmin")
                PercentNormView(label   : "Majoration pour enfants nés (\(viewModel.agirc.nbEnfantNe)) / à charge (\(viewModel.agirc.nbEnfantACharge) en \(viewModel.agirc.dateLiquidation?.year ?? 0))",
                                percent : (viewModel.agirc.majorationEnfant/(viewModel.agirc.pensionBrute-viewModel.agirc.majorationEnfant)),
                                comment : "Menf")
                AmountView(label   : "Pension annuelle brute (non dévaluée)",
                           amount  : viewModel.agirc.pensionBrute,
                           comment : "Brut = Npt x Vpt x Cmin x (1 + Menf)")
                AmountView(label   : "Pension annuelle nette (non dévaluée)",
                           amount  : viewModel.agirc.pensionNette, weight  : .bold,
                           comment : "Net = Brut - Prélev sociaux")
            },
            label: { HeaderView }
        )
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
