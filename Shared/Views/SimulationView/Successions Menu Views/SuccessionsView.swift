//
//  SuccessionsView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import ModelEnvironment
import Succession
import LifeExpense
import Persistence
import PatrimoineModel
import FamilyModel
import HelpersView
import SimulationAndVisitors

struct SuccessionsView: View {
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    var title: String
    
    var successions: [Succession]
    
    var body: some View {
        if successions.isEmpty {
            Text("Pas de décès pendant la dernière simulation")
        } else {
            List {
                // Cumul global des successions
                GroupBox(
                    content: {
                        Group {
                            Group {
                                AmountView(label : "Masse successorale taxable brute (évaluation fiscale)",
                                           amount: successions.sum(for: \.taxableValue))
                                AmountView(label : "Droits de succession à payer par les héritiers",
                                           amount: -successions.sum(for: \.tax),
                                           comment: (successions.sum(for: \.tax) / successions.sum(for: \.taxableValue)).percentStringRounded)
                                AmountView(label : "Net (évaluation fiscale)",
                                           amount: successions.sum(for: \.netFiscal))
                                Divider()
                                AmountView(label  : "Somme des héritages reçu brut (en cash)",
                                           amount : successions.sum(for: \.received))
                                AmountView(label  : "Somme des héritages reçu net (en cash)",
                                           amount : successions.sum(for: \.receivedNet))
                                AmountView(label  : "Somme des créance de restitution des héritiers envers le quasi-usufruitier",
                                           amount : successions.sum(for: \.creanceRestit))
                            }
                            .foregroundColor(.secondary)
                            .padding(.top, 3)
                            Divider()
                            CumulatedSuccessorsDisclosureGroup(successions: successions)
                        }
                        .padding(.leading)
                    },
                    label: {
                        Label("Cumulatif des Successions", systemImage: "plus").font(.headline)
                    })
                
                // liste des successsions dans le temps
                ForEach(successions.sorted(by: \.yearOfDeath)) { succession in
                    SuccessionGroupBox(succession: succession)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    //    init(simulation: Simulation) {
    //        self.successions = simulation.occuredLegalSuccessions
    //    }
}

struct CumulatedSuccessorsDisclosureGroup: View {
    var successions: [Succession]
    
    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(successions.successorsReceivedNetValue.keys.sorted(), id:\.self) { name in
                    GroupBox(label: Text(name).font(.headline)) {
                        AmountView(label  : "Somme des héritages reçu net (en cash)",
                                   amount : successions.successorsReceivedNetValue[name]!)
                        .foregroundColor(.secondary)
                        .padding(.top, 3)
                    }
                }
            },
            label: {
                Text("Héritiers").font(.headline)
            })
    }
}

struct SuccessionGroupBox: View {
    var succession: Succession
    var nature: String {
        succession.kind.rawValue
    }
    @EnvironmentObject private var family: Family
    
    var body: some View {
        GroupBox(
            content: {
                Group {
                    Group {
                        AmountView(label : "Masse successorale taxable brute (évaluation fiscale)",
                                   amount: succession.taxableValue)
                        AmountView(label : "Droits de succession à payer par les héritiers",
                                   amount: -succession.tax,
                                   comment: (succession.tax / succession.taxableValue).percentStringRounded)
                        AmountView(label : "Net (évaluation fiscale)",
                                   amount: succession.netFiscal)
                        Divider()
                        AmountView(label  : "Somme des héritages reçu brut (en cash)",
                                   amount : succession.received)
                        AmountView(label  : "Somme des héritages reçu net (en cash)",
                                   amount : succession.receivedNet)
                        AmountView(label  : "Somme des créance de restitution des héritiers envers le quasi-usufruitier",
                                   amount : succession.creanceRestit)
                    }
                    .foregroundColor(.secondary)
                    .padding(.top, 3)
                    Divider()
                    SuccessorsDisclosureGroup(successionKind : succession.kind,
                                              inheritances   : succession.inheritances)
                }
                .padding(.leading)
            },
            label: {
                Label {
                    Text("Succession \(nature) de ").fontWeight(.regular) +
                    Text("\(succession.decedentName) ") +
                    Text("à l'âge de \(family.ageOf(succession.decedentName, succession.yearOfDeath)) ans ").fontWeight(.regular) +
                    Text("en \(String(succession.yearOfDeath))").fontWeight(.regular)
                } icon: {
                    Image(systemName: "person.fill")
                }
            })
    }
}

struct SuccessorsDisclosureGroup: View {
    var successionKind : SuccessionKindEnum
    var inheritances   : [Inheritance]
    
    var body: some View {
        DisclosureGroup(
            content: {
                ForEach(inheritances, id: \.successorName) { inheritence in
                    SuccessorGroupBox(successionKind : successionKind,
                                      inheritence    : inheritence)
                }
            },
            label: {
                Text("Héritiers").font(.headline)
            })
    }
}

struct SuccessionsView_Previews: PreviewProvider {
    static func initializedSimulation() -> Simulation {
        TestEnvir.loadTestFilesFromBundle()
        TestEnvir.simulation.compute(using          : TestEnvir.model,
                                     nbOfYears      : 55,
                                     nbOfRuns       : 1,
                                     withFamily     : TestEnvir.family,
                                     withExpenses   : TestEnvir.expenses,
                                     withPatrimoine : TestEnvir.patrimoine)
        return TestEnvir.simulation
    }
    
    static var previews: some View {
        let simulation = initializedSimulation()
        
        return SuccessionsView(title       : "Successions Légales",
                               successions : simulation.occuredLegalSuccessions)
        .preferredColorScheme(.dark)
        .environmentObject(TestEnvir.uiState)
        .environmentObject(TestEnvir.family)
        .environmentObject(TestEnvir.patrimoine)
        .environmentObject(TestEnvir.simulation)
    }
}
