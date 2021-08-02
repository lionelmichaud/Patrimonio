//
//  FiscalChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import AppFoundation
import Charts // https://github.com/danielgindi/Charts.git
import Files
import ModelEnvironment
import Persistence

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.IrppEvolutionChartView")

// MARK: - Evolution de la Fiscalité dans le temps Charts Views

struct IrppEvolutionChartView: View {
    @EnvironmentObject var dataStore : Store
    @EnvironmentObject var simulation: Simulation
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des taux d'imposition sur le revenu (IRPP).
        Evolution du revenu imposable à l'IRRP et du montant de l'IRPP.

        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """

    var body: some View {
        VStack {
            IrppEvolutionLineChartView(socialAccounts : $simulation.socialAccounts,
                                       title          : simulation.title)
            IrppTranchesLineChartView(socialAccounts : $simulation.socialAccounts,
                                      title          : simulation.title)
        }
        .padding(.trailing, 4)
        .navigationTitle("Evolution de l'Impôt sur le Revenu")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: { saveImages(to: dataStore.activeDossier!.folder!) },
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
    
    func saveImages(to folder: Folder) {
        IrppEvolutionLineChartView.saveImage(to: folder)
        IrppTranchesLineChartView.saveImage(to: folder)
    }
}

// MARK: - Wrappers de UIView

/// Wrapper de CombinedChartView: EVOLUTION dans le temps des Taux d'imposition et du Quotient familial
struct IrppEvolutionLineChartView: UIViewRepresentable {
    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : CombinedChartView?
    static var snapshotNb  : Int    = 0

    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts

    // MARK: - Initializer

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IrppEvolutionLineChartView.titleStatic = title
        self._socialAccounts               = socialAccounts
    }
    
    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard IrppEvolutionLineChartView.uiView != nil else {
            #if DEBUG
            print("error: no chartView to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IrppEvolutionLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: no image to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Taux-" + String(IrppEvolutionLineChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        IrppEvolutionLineChartView.snapshotNb += 1
    }
    
    // MARK: - Methods

    func updateData(of chartView: CombinedChartView) {
        // LIGNES
        let visitor = IrppRateChartCashFlowVisitor(element: socialAccounts.cashFlowArray)
        let lineDataSets = visitor.lineDataSets
        // ajouter les DataSet au ChartData
        let lineChartData = LineChartData(dataSets: lineDataSets)
        lineChartData.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        lineChartData.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        lineChartData.setValueFormatter(DefaultValueFormatter(formatter: decimalX100IntegerFormatter))

        // BARRES
        // créer les DataSet : BarChartDataSets
        let barDataSets = visitor.barDataSets
        // ajouter les DataSet au ChartData
        let barChartData = BarChartData(dataSets: barDataSets)
        barChartData.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        barChartData.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        barChartData.setValueFormatter(DefaultValueFormatter(formatter: decimalFormatter))

        // combiner les ChartData
        let data = CombinedChartData()
        data.lineData = lineChartData
        data.barData  = barChartData
        //        data.bubbleData = generateBubbleData()
        //        data.scatterData = generateScatterData()
        //        data.candleData = generateCandleData()

        // ajouter le Chartdata au ChartView
        chartView.data = data

        chartView.data?.notifyDataChanged()
   }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> CombinedChartView {
        // créer et configurer un nouveau graphique
        let chartView = CombinedChartView(title                   : "Paramètres Imposition",
                                          smallLegend             : false,
                                          leftAxisFormatterChoice : .percent)

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppEvolutionLineChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: CombinedChartView, context: Context) {
        uiView.clear()
        updateData(of: uiView)

        uiView.notifyDataSetChanged()
    }
}

/// Wrapper de LineChartView: EVOLUTION dans le temps de l'IRPP
struct IrppTranchesLineChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : LineChartView?
    static var snapshotNb  : Int    = 0

    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts

    // MARK: - Initializer

    internal init(socialAccounts : Binding<SocialAccounts>, title: String) {
        IrppTranchesLineChartView.titleStatic = title
        self._socialAccounts          = socialAccounts
    }
    
    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard IrppTranchesLineChartView.uiView != nil else {
            #if DEBUG
            print("error: no chartView to save")
            #endif
            return
        }
        // construire l'image
        guard let image = IrppTranchesLineChartView.uiView!.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: no image to save")
            #endif
            return
        }
        
        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "IRPP-Evolution-" + String(IrppTranchesLineChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        IrppTranchesLineChartView.snapshotNb += 1
    }
    
    // MARK: - Methods

    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets =
            IrppChartCashFlowVisitor(element: socialAccounts.cashFlowArray)
            .dataSets

        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // ajouter le Chartdata au ChartView
        chartView.data = data

        chartView.data?.notifyDataChanged()
    }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Imposition",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        IrppTranchesLineChartView.uiView = chartView
        return chartView
    }
    
    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: LineChartView, context: Context) {
        uiView.clear()
        updateData(of: uiView)

        uiView.notifyDataSetChanged()
    }
}

struct IrppView_Previews: PreviewProvider {
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
                NavigationLink(destination : IrppEvolutionChartView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("IRPP Synthèse de l'évolution")
                }
                .isDetailLink(true)
            }
        }
    }
}
