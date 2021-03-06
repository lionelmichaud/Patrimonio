//
//  BalanceSheetChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 12/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.BalanceSheetGlobalChartView")

// MARK: - Balance Sheet Charts Views

/// Vue globale du bilan: Actif / Passif / Net
struct BalanceSheetGlobalChartView: View {
    @EnvironmentObject var simulation: Simulation
    @State private var lifeEventChatIsPresented = false
    var lastYear: Int? { simulation.socialAccounts.balanceArray.last?.year }
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des valeurs de l'ensemble des biens (actif et passif).
        détenus par l'ensemble des membres de la famille.

        Evolution du solde net.
        """
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                // graphique Blan
                BalanceSheetLineChartView(socialAccounts: $simulation.socialAccounts,
                                          title         : simulation.title)
                    .padding(.trailing, 4)

                // Graphique Evénement de Vie
                if lifeEventChatIsPresented {
                    FamilyLifeEventChartView(endDate: lastYear ?? Date.now.year + 30)
                        .frame(minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxHeight: geometry.size.height/4.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                        .padding(.trailing, 4)
                }
            }
        }
        .navigationTitle("Bilan")
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            // afficher/masquer le grpahique des événemnts de vie
            ToolbarItem(placement: .automatic) {
                Button(action: { withAnimation { lifeEventChatIsPresented.toggle() } },
                       label : { Image(systemName: lifeEventChatIsPresented ? "rectangle" : "rectangle.split.1x2") })
            }
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: BalanceSheetLineChartView.saveImage,
                       label : { Image(systemName: "camera.circle") })
            }
            // afficher info-bulle
            ToolbarItem(placement: .automatic) {
                Button(action: { self.showInfoPopover = true },
                       label : {
                        Image(systemName: "info.circle")
                       })
                    .popover(isPresented: $showInfoPopover) {
                        PopOverContentView(title       : popOverTitle,
                                           description : popOverMessage)
                    }
            }
        }
    }
}

// MARK: - Wrappers de UIView

/// Wrapper de LineChartView
struct BalanceSheetLineChartView: NSUIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0

    // MARK: - Properties

    @Binding var socialAccounts: SocialAccounts
    var title                   : String

    // MARK: - Initializer

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        BalanceSheetLineChartView.titleStatic = title
        self.title            = title
        self._socialAccounts  = socialAccounts
    }

    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard let chartView = BalanceSheetLineChartView.uiView else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = chartView.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-" + String(BalanceSheetLineChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: AppSettings.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", AppSettings.imagePath(titleStatic) + fileName)
            #endif
        } catch let error as NSError {
            fatalError("""
                Domain         : \(error.domain)
                Code           : \(error.code)
                Description    : \(error.localizedDescription)
                Failure Reason : \(error.localizedFailureReason ?? "")
                Suggestions    : \(error.localizedRecoverySuggestion ?? "")
                """)
        }
        BalanceSheetLineChartView.snapshotNb += 1
    }

    // MARK: - Methods

    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets = socialAccounts.getBalanceSheetLineChartDataSets()

        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // ajouter le Chartdata au ChartView
        chartView.data = data
        //chartView.data?.notifyDataChanged()
        //chartView.notifyDataSetChanged()

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
    }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Actif/Passif",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))

        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        BalanceSheetLineChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: LineChartView, context: Context) {
        updateData(of: uiView)
    }
}

// MARK: - Preview

struct BalanceSheetGlobalChartView_Previews: PreviewProvider {
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        // calcul de simulation
        simulation.compute(nbOfYears: 40, nbOfRuns: 1,
                           withFamily: family, withPatrimoine: patrimoine)
        return NavigationView {
            List {
                NavigationLink(destination : BalanceSheetGlobalChartView()
                                .environmentObject(uiState)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("Bilan Global")
                }
                .isDetailLink(true)
            }
        }
    }
}
