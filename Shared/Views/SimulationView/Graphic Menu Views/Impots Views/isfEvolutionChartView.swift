//
//  isfEvolutionChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 06/12/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import AppFoundation
import FiscalModel
import Charts // https://github.com/danielgindi/Charts.git
import Files
import ModelEnvironment
import Persistence

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.IsfEvolutionChartView")

// MARK: - Evolution de la Fiscalité dans le temps Charts Views

struct IsfEvolutionChartView: View {
    @EnvironmentObject var dataStore : Store
    @EnvironmentObject var simulation: Simulation
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps du montant de l'ISF dû.

        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """

    var body: some View {
        IsfLineChartView(socialAccounts : $simulation.socialAccounts,
                         title          : simulation.title)
            .padding(.trailing, 4)
            .navigationTitle("Evolution de l'Impôt sur la Fortune")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // sauvergarder l'image dans l'album photo
                ToolbarItem(placement: .automatic) {
                    Button(action: { IsfLineChartView.saveImage(to: dataStore.activeDossier!.folder!) },
                           label : { Image(systemName: "camera.circle") })
                        .disabled(dataStore.activeDossier == nil || dataStore.activeDossier!.folder == nil)
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

/// Wrapper de LineChartView: EVOLUTION dans le temps de l'ISF
struct IsfLineChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : LineChartView?
    static var snapshotNb  : Int    = 0
    
    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts

    // MARK: - Initializer

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IsfLineChartView.titleStatic = title
        self._socialAccounts         = socialAccounts
    }
    
    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard IsfLineChartView.uiView != nil else {
            #if DEBUG
            print("error: no chartView to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IsfLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: no image to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "ISF-Evolution-" + String(IsfLineChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        IsfLineChartView.snapshotNb += 1
    }
    
    // MARK: - Methods

    func format(_ chartView: LineChartView) {
        chartView.leftAxis.axisMinimum = 0.0
        chartView.leftAxis.enabled = true

        chartView.rightAxis.axisMinimum = 0.0
        chartView.rightAxis.enabled = true
    }

    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets =
            IsfChartCashFlowVisitor(element: socialAccounts.cashFlowArray)
            .dataSets

        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // seuil d'imposition à l'ISF
        let ll1 = ChartLimitLine(limit: Fiscal.model.isf.model.seuil, label: "Seuil d'imposition")
        ll1.lineWidth       = 2
        ll1.lineDashLengths = [10, 10]
        ll1.labelPosition   = .bottomLeft
        ll1.valueFont       = .systemFont(ofSize : 14)
        ll1.valueTextColor  = ChartThemes.DarkChartColors.labelTextColor
        chartView.leftAxis.removeAllLimitLines()
        chartView.leftAxis.addLimitLine(ll1)

        // ajouter le Chartdata au ChartView
        chartView.data = data

        chartView.data?.notifyDataChanged()
    }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Imposition sur la Fortune",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))

        format(chartView)

        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IsfLineChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.clear()
        //uiView.data?.clearValues()
        updateData(of: uiView)

        // animer la transition
        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)
        uiView.notifyDataSetChanged()
    }
}

struct IsfView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var dataStore  = Store()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        simulation.compute(using          : model,
                           nbOfYears      : 40,
                           nbOfRuns       : 1,
                           withFamily     : family,
                           withPatrimoine : patrimoine)
        return NavigationView {
            List {
                // calcul de simulation
                NavigationLink(destination : IsfEvolutionChartView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("ISF")
                }
                .isDetailLink(true)
            }
        }
    }
}
