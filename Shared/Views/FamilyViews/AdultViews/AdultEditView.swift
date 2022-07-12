//
//  AdultEditView.swift
//  Patrimonio (iOS)
//
//  Created by Lionel MICHAUD on 11/07/2022.
//

import SwiftUI
import FiscalModel
import UnemployementModel
import HelpersView

// MARK: - Saisie Adult
struct AdultEditView : View {
    var authorizeDeathAgeModification: Bool

    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Group {
            // Section scénario
            ScenarioEditSection(authorizeDeathAgeModification : authorizeDeathAgeModification,
                                personViewModel               : personViewModel,
                                adultViewModel                : adultViewModel)

            // Section activité principale
            MainActivityEditSection(adultViewModel: adultViewModel)

            // Section activité annexes
            SideWorksEditView(adultViewModel: adultViewModel)


            // Section retraite
            RetirementEditView(personViewModel : personViewModel,
                               adultViewModel   : adultViewModel)

            // Section dépendance
            DepedanceEditSection(adultViewModel: adultViewModel)
        }
    }
}

// MARK: - Saisie Adult / Section Scenario
private struct ScenarioEditSection: View {
    var authorizeDeathAgeModification: Bool

    @ObservedObject var personViewModel : PersonViewModel
    @ObservedObject var adultViewModel  : AdultViewModel

    var body: some View {
        Section {
            if authorizeDeathAgeModification {
                Stepper(value: $personViewModel.deathAge, in: Date().year - personViewModel.birthDate.year ... 100) {
                    HStack {
                        Text("Age de décès estimé ")
                        Spacer()
                        Text("\(personViewModel.deathAge) ans").foregroundColor(.secondary)
                    }
                }
            }
            HStack {
                Text("Option fiscale retenue en cas d'héritage")
                Spacer()
                CasePicker(pickedCase: $adultViewModel.fiscalOption, label: "Option fiscale retenue en cas d'héritage")
                    .pickerStyle(.segmented)
            }
        } header: {
            Text("SCENARIO").font(.subheadline)
        }
    }
}

// MARK: - Saisie Adult / Section Dépendance
private struct DepedanceEditSection: View {
    @ObservedObject var adultViewModel: AdultViewModel

    var body: some View {
        Section {
            Stepper(value: $adultViewModel.nbYearOfDepend, in: 0 ... 15) {
                HStack {
                    Text("Nombre d'année de dépendance ")
                    Spacer()
                    Text("\(adultViewModel.nbYearOfDepend) ans").foregroundColor(.secondary)
                }
            }
        } header: {
            Text("DEPENDANCE")
        }
    }
}

// MARK: - Saisie Adult / Section Activité
private struct MainActivityEditSection: View {
    @ObservedObject var adultViewModel: AdultViewModel

    var body: some View {
        Section {
            RevenueEditView(adultViewModel: adultViewModel)
            EndOfWorkingPeriodEditView(adultViewModel: adultViewModel)
        } header: {
            Text("ACTIVITÉ PRINCIPALE")
        }
    }
}

// MARK: - Saisie Adult / Section Activité / Saisie des revenus
private struct RevenueEditView : View {
    @ObservedObject var adultViewModel: AdultViewModel

    var body: some View {
        let salary = adultViewModel.revIndex == WorkIncomeType.salaryId

        return Group {
            CaseWithAssociatedValuePicker<WorkIncomeType>(caseIndex: $adultViewModel.revIndex, label: "")
                .pickerStyle(.segmented)
            if salary {
                AmountEditView(label    : "Salaire brut",
                               amount   : $adultViewModel.revenueBrut,
                               validity : .poz)
                AmountEditView(label    : "Salaire net de feuille de paye",
                               amount   : $adultViewModel.revenueNet,
                               validity : .poz)
                AmountEditView(label    : "Salaire imposable",
                               amount   : $adultViewModel.revenueTaxable,
                               validity : .poz)
                AmountEditView(label    : "Coût de la mutuelle (protec. sup.)",
                               amount   : $adultViewModel.insurance,
                               validity : .poz)
                DatePicker(selection           : $adultViewModel.fromDate,
                           in                  : 50.years.ago!...Date.now,
                           displayedComponents : .date,
                           label               : { Text("Date d'embauche"); Spacer() })
            } else {
                AmountEditView(label    : "BNC",
                               amount   : $adultViewModel.revenueBrut,
                               validity : .poz)
                AmountEditView(label    : "Charges (assurance, frais bancaires, services, CFE)",
                               amount   : $adultViewModel.insurance,
                               validity : .poz)
            }
        }
    }
}

// MARK: - Saisie Adult / Section Activité / Saisie fin de période d'activité professionnelle
private struct EndOfWorkingPeriodEditView: View {
    @ObservedObject var adultViewModel: AdultViewModel

    var body: some View {
        DatePicker(selection           : $adultViewModel.dateRetirement,
                   displayedComponents : .date,
                   label               : { Text("Date de cessation d'activité") })
        //                    .onChange(of: adultViewModel.dateRetirement) { newState in
        //                        if (newState > (self.member as! Adult).dateOfAgircPensionLiquid) ||
        //                            (newState > (self.member as! Adult).dateOfPensionLiquid) {
        //                            self.alertItem = AlertItem(title         : Text("La date de cessation d'activité est postérieure à la date de liquiditaion d'une pension de retraite"),
        //                                                       dismissButton : .default(Text("OK")))
        //                        }
        //                    }
        //                    .alert(item: $alertItem) { alertItem in myAlert(alertItem: alertItem) }
        CasePicker(pickedCase : $adultViewModel.causeOfRetirement,
                   label      : "Cause")
        .pickerStyle(.segmented)
        if adultViewModel.causeOfRetirement != Unemployment.Cause.demission {
            Toggle(isOn: $adultViewModel.hasAllocationSupraLegale, label: { Text("Indemnité de licenciement non conventionnelle (supra convention)") })
            if adultViewModel.hasAllocationSupraLegale {
                AmountEditView(label    : "Montant total brut",
                               amount   : $adultViewModel.allocationSupraLegale,
                               validity : .poz)
                .padding(.leading)
            }
        }
    }
}

struct SideWorksEditView : View {
    @ObservedObject var adultViewModel: AdultViewModel

    var body: some View {
        Section {
            Button {
                withAnimation {
                    let newSidework = SideWork(
                        name       : "Nouvelle activité",
                        workIncome : WorkIncomeType.salaryPrototype,
                        startDate  : Date.now,
                        endDate    : 1.years.fromNow!)
                    adultViewModel.sideWorks.append(newSidework)
                }
            } label: {
                Label(title: { Text("Ajouter une activité") },
                      icon : { Image(systemName: "plus.circle.fill") })
                .foregroundColor(.accentColor)
            }

            List($adultViewModel.sideWorks) { $sideWork in
                DisclosureGroup {
                    SideworkRevenueEditView(sideWork: $sideWork)
                } label: {
                    TextField("Nom", text: $sideWork.name)
                        .textFieldStyle(.roundedBorder)
                        .padding(.trailing, 20)
                }
                .listItemSwipeActions(duplicateItem : { duplicate(sideWork) },
                                      deleteItem    : { delete(sideWork) })
            }
        } header: {
            Text("ACTIVITÉS ANNEXES")
        }
    }

    /// Dupliquer l'item sélectionné
    private func duplicate(_ sideWork: SideWork) {
        withAnimation {
            var copy = sideWork
            copy.name += "-copie"
            copy.id = UUID()
            adultViewModel.sideWorks.append(copy)
        }
    }

    /// Supprimer l'item sélectionné
    private func delete(_ sideWork: SideWork) {
        withAnimation {
            adultViewModel.sideWorks.removeAll(where: { $0.id == sideWork.id })
        }
    }

}

struct SideworkRevenueEditView : View {
    @Binding var sideWork: SideWork
    @State private var revIndex: Int = WorkIncomeType.salaryId
    @State private var brutSalary: Double = 0
    @State private var taxableSalary: Double = 0
    @State private var netSalary: Double = 0
    @State private var healthInsurance: Double = 0
    @State private var BNC: Double = 0
    @State private var fromDate: Date = Date.now
    @State private var incomeLossInsurance: Double = 0

    var body: some View {
        DatePicker(selection           : $sideWork.startDate,
                   in                  : 5.years.ago!...,
                   displayedComponents : .date,
                   label               : { Text("Début d'activité") })
        DatePicker(selection           : $sideWork.endDate,
                   in                  : 5.years.ago!...,
                   displayedComponents : .date,
                   label               : { Text("Fin d'activité") })
        CaseWithAssociatedValuePicker<WorkIncomeType>(caseIndex: $revIndex, label: "")
            .pickerStyle(.segmented)
            .onChange(of: revIndex) { newIndex in
                if newIndex == WorkIncomeType.salaryId {
                    sideWork.workIncome = WorkIncomeType.salary(brutSalary      : brutSalary,
                                                                taxableSalary   : taxableSalary,
                                                                netSalary       : netSalary,
                                                                fromDate        : fromDate,
                                                                healthInsurance : healthInsurance)
                } else {
                    sideWork.workIncome = WorkIncomeType.turnOver(BNC                 : BNC,
                                                                  incomeLossInsurance : incomeLossInsurance)
                }
            }
            .onAppear {
                revIndex = sideWork.workIncome.id
                switch sideWork.workIncome {
                    case let .salary(brutSalary, taxableSalary, netSalary, fromDate, healthInsurance):
                        self.brutSalary      = brutSalary
                        self.taxableSalary   = taxableSalary
                        self.netSalary       = netSalary
                        self.fromDate        = fromDate
                        self.healthInsurance = healthInsurance

                    case let .turnOver(BNC, incomeLossInsurance):
                        self.BNC                 = BNC
                        self.incomeLossInsurance = incomeLossInsurance
                }
            }
        switch sideWork.workIncome {
            case .salary:
                AmountEditView(label    : "Salaire brut",
                               amount   : $brutSalary,
                               validity : .poz)
                .onChange(of: brutSalary) { _ in
                    updateSalary()
                }
                AmountEditView(label    : "Salaire net de feuille de paye",
                               amount   : $netSalary,
                               validity : .poz)
                .onChange(of: netSalary) { _ in
                    updateSalary()
                }
                AmountEditView(label    : "Salaire imposable",
                               amount   : $taxableSalary,
                               validity : .poz)
                .onChange(of: taxableSalary) { _ in
                    updateSalary()
                }
                AmountEditView(label    : "Coût de la mutuelle (protec. sup.)",
                               amount   : $healthInsurance,
                               validity : .poz)
                .onChange(of: healthInsurance) { _ in
                    updateSalary()
                }
            case .turnOver:
                AmountEditView(label    : "BNC",
                               amount   : $BNC,
                               validity : .poz)
                .onChange(of: BNC) { _ in
                    updateTurnOver()
                }
                AmountEditView(label    : "Charges (assurance, frais bancaires, services, CFE)",
                               amount   : $incomeLossInsurance,
                               validity : .poz)
                .onChange(of: incomeLossInsurance) { _ in
                    updateTurnOver()
                }
        }
    }

    // MARK: - Methods

    private func updateSalary() {
        sideWork.workIncome =
        WorkIncomeType.salary(brutSalary      : brutSalary,
                              taxableSalary   : taxableSalary,
                              netSalary       : netSalary,
                              fromDate        : fromDate,
                              healthInsurance : healthInsurance)
    }

    private func updateTurnOver() {
        sideWork.workIncome =
        WorkIncomeType.turnOver(BNC                 : BNC,
                                incomeLossInsurance : incomeLossInsurance)
    }
}


// MARK: - Previews

struct AdultEditView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return Form {
            AdultEditView(authorizeDeathAgeModification : true,
                          personViewModel               : PersonViewModel(),
                          adultViewModel                : AdultViewModel())
            .environmentObject(TestEnvir.dataStore)
            .environmentObject(TestEnvir.model)
            .environmentObject(TestEnvir.uiState)
            .environmentObject(TestEnvir.family)
            .environmentObject(TestEnvir.expenses)
            .environmentObject(TestEnvir.patrimoine)
            .environmentObject(TestEnvir.simulation)
        }
    }
}

struct ScenarioEditSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            ScenarioEditSection(authorizeDeathAgeModification : true,
                            personViewModel               : PersonViewModel(),
                            adultViewModel                : AdultViewModel())
        }
    }
}

struct ActivityEditSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            MainActivityEditSection(adultViewModel: AdultViewModel())
        }
    }
}

struct RevenueEditView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            RevenueEditView(adultViewModel: AdultViewModel())
        }
    }
}

struct EndOfWorkingPeriodEditView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            EndOfWorkingPeriodEditView(adultViewModel: AdultViewModel())
        }
    }
}

struct DepedanceEditSection_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            DepedanceEditSection(adultViewModel: AdultViewModel())
        }
    }
}
