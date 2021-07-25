//
//  FiscalSliceView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 21/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import AppFoundation
import Charts // https://github.com/danielgindi/Charts.git
import Files

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.FiscalSliceView")

// MARK: - Décompositon de l'impôt par tranche Charts Views

struct IrppSliceView: View {
    @EnvironmentObject var dataStore : Store
    @EnvironmentObject var simulation: Simulation
    @EnvironmentObject var family    : Family
    @EnvironmentObject var uiState   : UIState
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution du montant de l'IRPP dû dans chaque tranche du barême (avec et sans enfants).

        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """

    var body: some View {
        VStack {
            HStack {
                Text("Evaluation en ") + Text(String(Int(uiState.fiscalChartState.evalDate)))
                Slider(value : $uiState.fiscalChartState.evalDate,
                       in    : (simulation.socialAccounts.cashFlowArray.first?.year.double())! ... (simulation.socialAccounts.cashFlowArray.last?.year.double())! - 1,
                       step  : 1,
                       onEditingChanged: {_ in
                       })
                Text(String(simulation.socialAccounts.cashFlowArray.last!.year - 1))
            }
            .padding(.horizontal)
            IrppSlicesStackedBarChartView(family         : family,
                                          socialAccounts : $simulation.socialAccounts,
                                          evalYear       : uiState.fiscalChartState.evalDate,
                                          title          : simulation.title)
        }
        .padding(.trailing, 4)
        .navigationTitle("Décomposition par tranche d'imposition")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: { IrppSlicesStackedBarChartView.saveImage(to: dataStore.activeDossier!.folder!) },
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

struct IrppSlicesStackedBarChartView: UIViewRepresentable {
    
    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : BarChartView?
    static var snapshotNb  : Int    = 0
    
    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var family                  : Family
    var evalYear                : Double
    
    // MARK: - Initializer

    internal init(family         : Family,
                  socialAccounts : Binding<SocialAccounts>,
                  evalYear       : Double,
                  title          : String) {
        IrppSlicesStackedBarChartView.titleStatic = title
        self.family                               = family
        self.evalYear                             = evalYear
        self._socialAccounts                      = socialAccounts
    }
    
    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard IrppSlicesStackedBarChartView.uiView != nil else {
            #if DEBUG
            print("error: no chartView to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IrppSlicesStackedBarChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: no image to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Tranches-" + String(IrppSlicesStackedBarChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        IrppSlicesStackedBarChartView.snapshotNb += 1
    }
    
    // MARK: - Methods

    func format(_ chartView: BarChartView) {
        chartView.leftAxis.axisMinimum     = 0
        chartView.leftAxis.axisMaximum     = 100_000
        chartView.xAxis.labelRotationAngle = 0
        chartView.xAxis.valueFormatter     = IrppValueFormatter()
        chartView.xAxis.labelFont          = ChartThemes.ChartDefaults.largeLegendFont
        chartView.chartDescription?.font   = .systemFont(ofSize: 13)
    }

    func updateData(of chartView: BarChartView) {
        // créer le DataSet: BarChartDataSet
        let year = Int(evalYear)
        let visitor = IrppSliceChartCashFlowVisitor(element    : socialAccounts.cashFlowArray,
                                                    for        : year,
                                                    nbAdults   : family.nbOfAdultAlive(atEndOf: year),
                                                    nbChildren : family.nbOfFiscalChildren(during: year))
        let dataSet = visitor.dataSets

        // ajouter les DataSet au Chartdata
        let data = BarChartData(dataSet: dataSet)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(UIFont(name:"HelveticaNeue-Light", size:12)!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // Lignes Taux d'imposition à l'IRPP
        chartView.leftAxis.removeAllLimitLines()
        for idx in visitor.slicesLimit.startIndex..<visitor.slicesLimit.endIndex {
            let lineLimit = ChartLimitLine(limit: visitor.slicesLimit[idx],
                                           label: "< \(visitor.slicesLimit[idx].k€String): \(dataSet?.stackLabels[idx] ?? "")")
            lineLimit.lineWidth       = 2
            lineLimit.lineDashLengths = [10, 10]
            lineLimit.labelPosition   = .bottomLeft
            lineLimit.valueFont       = .systemFont(ofSize : 14)
            lineLimit.valueTextColor  = ChartThemes.DarkChartColors.labelTextColor
            chartView.leftAxis.addLimitLine(lineLimit)
        }
        chartView.chartDescription?.text = "Répartition du revenu imposable (\(Int(evalYear)))"

        // ajouter le dataset au graphique
        chartView.data = data
        chartView.leftAxis.axisMaximum = 100_000

        chartView.data?.notifyDataChanged()
    }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BarChartView {
        // créer et configurer un nouveau bar graphique
        let chartView = BarChartView(title               : "Répartition du revenu imposable (\(Int(evalYear)))",
                                     smallLegend         : false,
                                     axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        format(chartView)

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)

        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppSlicesStackedBarChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: BarChartView, context: Context) {
        uiView.clear()
        //uiView.data?.clearValues()
        updateData(of: uiView)

        uiView.notifyDataSetChanged()
    }
}

struct IrppSliceView_Previews: PreviewProvider {
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
                NavigationLink(destination : IrppSliceView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("IRPP Tranches")
                }
                .isDetailLink(true)
            }
        }
    }
}
