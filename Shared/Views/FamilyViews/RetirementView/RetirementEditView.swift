//
//  RetirementEditView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import RetirementModel
import ModelEnvironment

// MARK: - Saisie pension retraite

struct RetirementEditView: View {
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel
    @State private var alertItem : AlertItem?
    
    var body : some View {
        Group {
            // régime complémentaire
            RegimeAgircEditView(personViewModel : personViewModel,
                                adultViewModel  : adultViewModel)
                .onChange(of: adultViewModel.ageAgircPension) { newAgeAgircPension in
                    if (newAgeAgircPension > adultViewModel.agePension) ||
                        (newAgeAgircPension == adultViewModel.agePension && adultViewModel.moisAgircPension > adultViewModel.moisPension) {
                        adultViewModel.ageAgircPension  = adultViewModel.agePension
                        adultViewModel.moisAgircPension = adultViewModel.moisPension
                        self.alertItem = AlertItem(title         : Text("La pension complémentaire doit être liquidée avant la pension base"),
                                                   dismissButton : .default(Text("OK")))
                    }
                }
                .onChange(of: adultViewModel.moisAgircPension) { newMoisAgircPension in
                    if adultViewModel.ageAgircPension == adultViewModel.agePension && newMoisAgircPension > adultViewModel.moisPension {
                        adultViewModel.ageAgircPension  = adultViewModel.agePension
                        adultViewModel.moisAgircPension = adultViewModel.moisPension
                        self.alertItem = AlertItem(title         : Text("La pension complémentaire doit être liquidée avant la pension base"),
                                                   dismissButton : .default(Text("OK")))
                    }
                }
            // régime général
            RegimeGeneralEditView(personViewModel : personViewModel,
                                  adultViewModel  : adultViewModel)
                .onChange(of: adultViewModel.agePension) { newAgePension in
                    if (newAgePension < adultViewModel.ageAgircPension) ||
                        (newAgePension == adultViewModel.ageAgircPension && adultViewModel.moisAgircPension > adultViewModel.moisPension) {
                        adultViewModel.agePension  = adultViewModel.ageAgircPension
                        adultViewModel.moisPension = adultViewModel.moisAgircPension
                        self.alertItem = AlertItem(title         : Text("La pension complémentaire doit être liquidée avant la pension base"),
                                                   dismissButton : .default(Text("OK")))
                    }
                }
                .onChange(of: adultViewModel.moisPension) { newMoisPension in
                    if adultViewModel.ageAgircPension == adultViewModel.agePension && adultViewModel.moisAgircPension > newMoisPension {
                        adultViewModel.agePension  = adultViewModel.ageAgircPension
                        adultViewModel.moisPension = adultViewModel.moisAgircPension
                        self.alertItem = AlertItem(title         : Text("La pension complémentaire doit être liquidée avant la pension base"),
                                                   dismissButton : .default(Text("OK")))
                    }
                }
        }
        .alert(item: $alertItem, content: createAlert)
    }
}

// MARK: - Saisie de la situation - Régime complémentaire

struct RegimeAgircEditView: View {
    @EnvironmentObject private var model: Model
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel
    
    var body: some View {
        Section(header: Text("RETRAITE - Régime complémentaire")) {
            HStack {
                Stepper(value: $adultViewModel.ageAgircPension,
                        in: model.retirementModel.regimeAgirc.ageMinimum ... model.retirementModel.regimeGeneral.ageTauxPleinLegal(birthYear: personViewModel.birthDate.year)!) {
                    HStack {
                        Text("Age de liquidation")
                        Spacer()
                        Text("\(adultViewModel.ageAgircPension) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $adultViewModel.moisAgircPension, in: 0...11) {
                    Text("\(adultViewModel.moisAgircPension) mois").foregroundColor(.secondary)
                }
                .frame(width: 160)
            }
            RegimeAgircSituationEditView(lastKnownAgircSituation: $adultViewModel.lastKnownAgircSituation)
        }
    }
}

struct RegimeAgircSituationEditView : View {
    @Binding var lastKnownAgircSituation: RegimeAgircSituation
    
    var body: some View {
        Group {
            IntegerEditView(label   : "Date de la dernière situation connue",
                            integer : $lastKnownAgircSituation.atEndOf)
            IntegerEditView(label   : "Nombre de points total acquis",
                            integer : $lastKnownAgircSituation.nbPoints)
            IntegerEditView(label   : "Nombre de points acquis par an",
                            integer : $lastKnownAgircSituation.pointsParAn)
        }
    }
}

// MARK: - Saisie de la situation - Régime général

struct RegimeGeneralEditView: View {
    @EnvironmentObject private var model: Model
    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel
    
    var body: some View {
        Section(header: Text("RETRAITE - Régime général")) {
            // régime complémentaire
            HStack {
                Stepper(value: $adultViewModel.agePension,
                        in: model.retirementModel.regimeGeneral.ageMinimumLegal ... model.retirementModel.regimeGeneral.ageTauxPleinLegal(birthYear: personViewModel.birthDate.year)!) {
                    HStack {
                        Text("Age de liquidation")
                        Spacer()
                        Text("\(adultViewModel.agePension) ans").foregroundColor(.secondary)
                    }
                }
                Stepper(value: $adultViewModel.moisPension, in: 0...11) {
                    Text("\(adultViewModel.moisPension) mois").foregroundColor(.secondary)
                }
                .frame(width: 160)
            }
            RegimeGeneralSituationEditView(lastKnownPensionSituation: $adultViewModel.lastKnownPensionSituation)
        }
    }
}

struct RegimeGeneralSituationEditView : View {
    @Binding var lastKnownPensionSituation: RegimeGeneralSituation
    
    var body: some View {
        Group {
            AmountEditView(label  : "Salaire annuel moyen",
                           amount : $lastKnownPensionSituation.sam)
            IntegerEditView(label   : "Date de la dernière situation connue",
                            integer : $lastKnownPensionSituation.atEndOf)
            IntegerEditView(label   : "Nombre de trimestre acquis",
                            integer : $lastKnownPensionSituation.nbTrimestreAcquis)
        }
    }
}

struct RetirementEditView_Previews: PreviewProvider {
    static var model = Model(fromBundle: Bundle.main)

    static var previews: some View {
        Form {
            RetirementEditView(personViewModel : PersonViewModel(),
                               adultViewModel  : AdultViewModel())
                .environmentObject(model)
        }
    }
}
