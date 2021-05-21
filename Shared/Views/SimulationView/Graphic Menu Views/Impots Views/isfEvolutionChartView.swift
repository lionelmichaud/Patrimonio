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
import Disk // https://github.com/saoudrizwan/Disk.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.IsfEvolutionChartView")

// MARK: - Evolution de la Fiscalité dans le temps Charts Views

struct IsfEvolutionChartView: View {
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
                    Button(action: IsfLineChartView.saveImage,
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

/// Wrapper de LineChartView: EVOLUTION dans le temps de l'ISF
struct IsfLineChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic      : String = "image"
    static var uiView           : LineChartView?
    static var snapshotNb       : Int = 0
    
    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var title                   : String

    // MARK: - Initializer

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IsfLineChartView.titleStatic = title
        self.title                   = title
        self._socialAccounts         = socialAccounts
    }
    
    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard IsfLineChartView.uiView != nil else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IsfLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Evolution-" + String(IsfLineChartView.snapshotNb) + ".png"
        do {
            try Disk.save(image, to: .documents, as: AppSettings.shared.imagePath(titleStatic) + fileName)
            // impression debug
            #if DEBUG
            Swift.print("saving image to file: ", AppSettings.shared.imagePath(titleStatic) + fileName)
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
    static var uiState    = UIState()
    static var family     = Family()
    static var patrimoine = Patrimoin()
    static var simulation = Simulation()

    static var previews: some View {
        simulation.compute(nbOfYears: 40, nbOfRuns: 1,
                           withFamily: family, withPatrimoine: patrimoine)
        return NavigationView {
            List {
                // calcul de simulation
                NavigationLink(destination : IsfEvolutionChartView()
                                .environmentObject(uiState)
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
