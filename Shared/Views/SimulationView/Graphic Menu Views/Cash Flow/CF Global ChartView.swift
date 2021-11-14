//
//  CashFlowChartView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import os
import SwiftUI
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git
import Files
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.CashFlowGlobalChartView")

// MARK: - Cash Flow Global Charts Views

/// Vue globale du cash flow: Revenus / Dépenses / Net
struct CashFlowGlobalChartView: View {
    @EnvironmentObject var dataStore  : Store
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var lifeEventChatIsPresented = false
    var lastYear: Int? { simulation.socialAccounts.cashFlowArray.last?.year }
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des flux de trésorerie annuels de l'ensemble des membres de la famille.
        Evolution du solde net.

        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """

    var body: some View {
        GeometryReader { geometry in
            VStack {
                // sélecteur: Adults / Enfants
                Picker(selection: self.$uiState.cfChartState.parentChildrenSelection, label: Text("Personne")) {
                    Text(AppSettings.shared.adultsLabel)
                        .tag(AppSettings.shared.adultsLabel)
                    Text(AppSettings.shared.childrenLabel)
                        .tag(AppSettings.shared.childrenLabel)
                }
                .padding(.horizontal)
                .pickerStyle(SegmentedPickerStyle())
                
                CashFlowLineChartView(for            : uiState.cfChartState.parentChildrenSelection,
                                      socialAccounts : $simulation.socialAccounts,
                                      title          : simulation.title)
                    .padding(.trailing, 4)

                // Graphique Evénement de Vie
                if lifeEventChatIsPresented {
                    FamilyLifeEventChartView(endDate: lastYear ?? Date.now.year + 30)
                        .frame(minHeight: 0, idealHeight: 100, maxHeight: geometry.size.height/4.0, alignment: .center)
                        .padding(.trailing, 4)
                }
            }
        }
        .navigationTitle("Cash Flow")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // afficher/masquer le grpahique des événemnts de vie
            ToolbarItem(placement: .automatic) {
                Button(action: { withAnimation { lifeEventChatIsPresented.toggle() } },
                       label : { Image(systemName: lifeEventChatIsPresented ? "rectangle" : "rectangle.split.1x2") })
            }
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: { CashFlowLineChartView.saveImage(to: dataStore.activeDossier!.folder!) },
                       label : { Image(systemName: "camera.circle") })
                    .disabled(dataStore.activeDossier == nil || dataStore.activeDossier!.folder == nil)
            }
            // afficher info-bulle
            ToolbarItem(placement: .automatic) {
                Button(action: { self.showInfoPopover = true },
                       label : {
                        Image(systemName: "info.circle")//.font(.largeTitle)
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
struct CashFlowLineChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : LineChartView?
    static var snapshotNb  : Int    = 0
    
    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var parentChildrenSelection: String

    // MARK: - Initializer
    
    internal init(for parentChildrenSelection : String,
                  socialAccounts              : Binding<SocialAccounts>,
                  title                       : String) {
        CashFlowLineChartView.titleStatic = title
        self.parentChildrenSelection      = parentChildrenSelection
        self._socialAccounts              = socialAccounts
    }
    
    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard let chartView =  CashFlowLineChartView.uiView else {
            #if DEBUG
            print("error: nothing chartView to save")
            #endif
            return
        }
        // construire l'image
        guard let image = chartView.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing image to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "CashFlow-" + String(CashFlowLineChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        CashFlowLineChartView.snapshotNb += 1
    }
    
    // MARK: - Methods

    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets =
            LineChartCashFlowVisitor(
                element         : socialAccounts.cashFlowArray,
                personSelection : parentChildrenSelection)
            .dataSets
        
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
        let chartView = LineChartView(title               : "Revenu / Dépense",
                                      smallLegend         : false,
                                      axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))
        
        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        CashFlowLineChartView.uiView = chartView
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

struct CashFlowGlobalChartView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var dataStore  = Store()
    static var family     = try! Family(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var expenses   = try! LifeExpensesDic(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var patrimoine = try! Patrimoin(fromFolder: try! PersistenceManager.importTemplatesFromApp())
    static var simulation = Simulation()

    static var previews: some View {
        // calcul de simulation
        simulation.compute(using          : model,
                           nbOfYears      : 40,
                           nbOfRuns       : 1,
                           withFamily     : family,
                           withExpenses   : expenses,
                           withPatrimoine : patrimoine)
        return NavigationView {
            List {
                NavigationLink(destination : CashFlowGlobalChartView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("Cash Flow Global")
                }
                .isDetailLink(true)
            }
        }
    }
}
