//
//  RealEstateDetailedView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import DateBoundary
import AssetsModel
import PatrimoineModel
import FamilyModel
import SimulationAndVisitors
import HelpersView

// MARK: - View

struct RealEstateDetailedView: View {
    let updateDependenciesToModel : () -> Void
    @Transac var item : RealEstateAsset

    var body: some View {
        Form {
            LabeledTextField(label       : "Nom",
                             defaultText : "obligatoire",
                             text        : $item.name,
                             validity    : .notEmpty)
            LabeledTextEditor(label: "Note", text: $item.note)
            WebsiteEditView(website: $item.website)

            /// acquisition
            Section {
                NavigationLink(destination: Form { BoundaryEditView2(label    : "Première année de possession",
                                                                    boundary : $item.buyingYear) }) {
                    HStack {
                        Text("Première année de possession")
                        Spacer()
                        Text(String((item.buyingYear.description)))
                    }.foregroundColor(item.buyingYear.isValid ? .blue : .red)
                }
                AmountEditView(label    : "Prix d'acquisition",
                               amount   : $item.buyingPrice,
                               validity : .poz)
            } header: {
                Text("ACQUISITION")
            }

            /// valeur vénale courante estimée
            Section {
                AmountEditView(label    : "Valeur vénale courante estimée",
                               amount   : $item.estimatedValue,
                               validity : .poz)
            } header: {
                Text("VALEUR VENALE")
            }
            
            /// propriété
            OwnershipView(ownership  : $item.ownership,
                          totalValue : item.value(atEndOf : CalendarCst.thisYear))
            
            /// taxe
            Section {
                AmountEditView(label    : "Taxe d'habitation annuelle",
                               amount   : $item.yearlyTaxeHabitation,
                               validity : .poz)
                AmountEditView(label    : "Taxe fonçière annuelle",
                               amount   : $item.yearlyTaxeFonciere,
                               validity : .poz)
            } header: {
                Text("TAXES")
            }
            
            /// habitation
            Section {
                Toggle("Période d'occupation", isOn: $item.willBeInhabited.animation())
                if item.willBeInhabited {
                    FromToEditView(from : $item.inhabitedFrom,
                                   to   : $item.inhabitedTo)
                        .padding(.leading)
                }
            } header: {
                Text("HABITATION")
            }
            
            /// location
            Section {
                Toggle("Période de location", isOn: $item.willBeRented.animation())
                if item.willBeRented {
                    Group {
                        FromToEditView(from : $item.rentalFrom,
                                       to   : $item.rentalTo)
                        AmountEditView(label    : "Loyer mensuel net de frais",
                                       amount   : $item.monthlyRentAfterCharges,
                                       validity : .poz)
                        AmountView(label : "Charges sociales annuelles sur loyers",
                                   amount: item.yearlyRentSocialTaxes)
                        .foregroundColor(.secondary)
                        AmountView(label : "Loyer annuel net de charges sociales",
                                   amount: item.yearlyRentAfterCharges)
                        .foregroundColor(.secondary)
                        PercentNormView(label : "Rendement locatif net de charges sociales",
                                        percent   : item.profitability)
                        .foregroundColor(.secondary)
                    }.padding(.leading)
                }
            } header: {
                Text("LOCATION")
            }
            
            /// vente
            Section {
                Toggle("Sera vendue", isOn: $item.willBeSold.animation())
                if item.willBeSold {
                    Group {
                        NavigationLink(destination: Form { BoundaryEditView2(label    : "Dernière année de possession",
                                                                            boundary : $item.sellingYear) }) {
                            HStack {
                                Text("Dernière année de possession")
                                Spacer()
                                Text(String((item.sellingYear.description)))
                            }.foregroundColor(.blue)
                        }
                        AmountEditView(label    : "Prix de vente net de frais",
                                       amount   : $item.sellingNetPrice,
                                       validity : .poz)
                        AmountView(label: "Produit net de charges et impôts",
                                   amount: item.sellingPriceAfterTaxes)
                            .foregroundColor(.secondary)
                    }.padding(.leading)
                }
            } header: {
                Text("VENTE")
            }
        }
        .textFieldStyle(.roundedBorder)
        .navigationTitle("Immeuble")
        /// barre d'outils de la NavigationView
        .modelChangesToolbar(subModel                  : $item,
                             isValid                   : item.isValid,
                             updateDependenciesToModel : updateDependenciesToModel)
    }
}

struct FromToEditView: View {
    @Binding var from : DateBoundary
    @Binding var to   : DateBoundary

    var correctOrder: Bool? {
        if let from = from.year, let to = to.year {
            return from < to
        } else {
            return nil
        }
    }

    var body: some View {
        Group {
            NavigationLink(destination: Form { BoundaryEditView2(label    : "Début",
                                                                 boundary : $from) }) {
                HStack {
                    Text("Début (année inclue)")
                    Spacer()
                    Text(String((from.description)))
                }.foregroundColor(from.isValid ? .blue : .red)
            }
            NavigationLink(destination: Form { BoundaryEditView2(label    : "Fin",
                                                                 boundary : $to) }) {
                HStack {
                    Text("Fin (année exclue)")
                    Spacer()
                    Text(String((to.description)))
                }.foregroundColor(to.isValid ? .blue : .red)
            }
            if let correctOrder = correctOrder {
                if !correctOrder {
                    Text("L'année de fin doit être postérieure à l'année de début")
                        .foregroundColor(.red)
                }
            }
        }
    }
}

struct RealEstateDetailedView_Previews: PreviewProvider {
    static var previews: some View {
        TestEnvir.loadTestFilesFromBundle()
        return NavigationView {
            RealEstateDetailedView(updateDependenciesToModel: { },
                                   item: .init(source: TestEnvir.patrimoine.assets.realEstates.items.first!))
                .environmentObject(TestEnvir.model)
            }
            .previewDisplayName("RealEstateDetailedView")
    }
}
