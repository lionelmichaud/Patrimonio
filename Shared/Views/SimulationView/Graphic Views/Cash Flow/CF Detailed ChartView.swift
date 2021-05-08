//
//  CF Detailed ChartViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 08/05/2021.
//

import os
import SwiftUI
import AppFoundation
import NamedValue
import Charts // https://github.com/danielgindi/Charts.git
import Disk // https://github.com/saoudrizwan/Disk.git

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimoine", category: "UI.CashFlowDetailedChartView")

// MARK: - Cash Flow Detailed Charts Views

/// Vue détaillée du cash flow: Revenus / Dépenses / Net
struct CashFlowDetailedChartView: View {
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var lifeEventChatIsPresented = false
    var lastYear: Int? { simulation.socialAccounts.cashFlowArray.last?.year }
    @State private var menuIsPresented = false
    let menuWidth: CGFloat = 200
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des des flux de trésorerie annuels de l'ensemble des membres de la famille.
        Evolution du solde net.
        Détail par catégorie de dépense / revenus.

        Utiliser le bouton 🔍 pour filtrer les catégories de dépense / revenus.
        Utiliser le bouton 🔳 pour faire apparaître un second grahique présentant l'ordre chronologique des événemnts de vie de chaque membre de la famille
        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                /// zone de graphique
                VStack {
                    // sélecteur: Actif / Passif / Tout
                    CasePicker(pickedCase: self.$uiState.cfChartState.combination, label: "")
                        .padding(.horizontal)
                        .pickerStyle(SegmentedPickerStyle())
                    if self.uiState.cfChartState.itemSelection.onlyOneCategorySelected() {
                        if let categoryName = self.uiState.cfChartState.itemSelection.firstCategorySelected() {
                            if categoryName == "Dépenses de vie" {
                                CasePicker(pickedCase: $uiState.cfChartState.selectedExpenseCategory, label: "Catégories de dépenses")
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding(.horizontal)
                            }
                        }
                    }
                    // graphique Cash-Flow
                    CashFlowStackedBarChartView(socialAccounts: self.$simulation.socialAccounts,
                                                title         : self.simulation.title,
                                                combination   : self.uiState.cfChartState.combination,
                                                itemSelection : self.uiState.cfChartState.itemSelection,
                                                expenses      : family.expenses,
                                                selectedExpenseCategory: self.uiState.cfChartState.selectedExpenseCategory)
                        .padding(.trailing, 4)

                    // Graphique Evénement de Vie
                    if lifeEventChatIsPresented {
                        FamilyLifeEventChartView(endDate: lastYear ?? Date.now.year + 30)
                            .frame(minHeight: /*@START_MENU_TOKEN@*/0/*@END_MENU_TOKEN@*/, idealHeight: /*@START_MENU_TOKEN@*/100/*@END_MENU_TOKEN@*/, maxHeight: geometry.size.height/4.0, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                            .padding(.trailing, 4)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .offset(x: self.menuIsPresented ? self.menuWidth : 0)

                /// slide out menu de filtrage des séries à afficher
                if self.menuIsPresented {
                    MenuContentView(itemSelection: self.$uiState.cfChartState.itemSelection)
                        .frame(width: self.menuWidth)
                        .transition(.move(edge: .leading))
                }
            }
        }
        .navigationTitle("Cash Flow Détaillé")
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            //  menu slideover de filtrage
            ToolbarItem(placement: .navigation) {
                Button(action: { withAnimation { self.menuIsPresented.toggle() } },
                       label: {
                        if self.uiState.cfChartState.itemSelection.allCategoriesSelected() {
                            Image(systemName: "magnifyingglass.circle")
                        } else {
                            Image(systemName: "magnifyingglass.circle.fill")
                        }
                       })//.capsuleButtonStyle()
            }
            // afficher/masquer le grpahique des événemnts de vie
            ToolbarItem(placement: .automatic) {
                Button(action: { withAnimation { lifeEventChatIsPresented.toggle() } },
                       label : { Image(systemName: lifeEventChatIsPresented ? "rectangle" : "rectangle.split.1x2") })
            }
            // sauvergarder l'image dans l'album photo
            ToolbarItem(placement: .automatic) {
                Button(action: CashFlowStackedBarChartView.saveImage,
                       label : { Image(systemName: "camera.circle") })
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

struct CashFlowStackedBarChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic      : String = "image"
    static var uiView           : BarChartView?
    static var snapshotNb       : Int = 0

    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var title                   : String
    var combination             : SocialAccounts.CashCombination
    var itemSelectionList       : ItemSelectionList
    var expenses                : LifeExpensesDic
    var selectedExpenseCategory : LifeExpenseCategory?

    // MARK: - Initializer

    internal init(socialAccounts          : Binding<SocialAccounts>,
                  title                   : String,
                  combination             : SocialAccounts.CashCombination,
                  itemSelection           : ItemSelectionList,
                  expenses                : LifeExpensesDic,
                  selectedExpenseCategory : LifeExpenseCategory? = nil) {
        CashFlowStackedBarChartView.titleStatic = title
        self.title                   = title
        self.combination             = combination
        self.itemSelectionList       = itemSelection
        self.expenses                = expenses
        self.selectedExpenseCategory = selectedExpenseCategory
        self._socialAccounts         = socialAccounts
    }

    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage() {
        guard let chartView = CashFlowStackedBarChartView.uiView else {
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
        let fileName = "CashFlow-detailed-" + String(CashFlowStackedBarChartView.snapshotNb) + ".png"
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
        CashFlowStackedBarChartView.snapshotNb += 1
    }

    // MARK: - Methods

    func updateData(of chartView: BarChartView) {
        //: ### BarChartData
        let aDataSet : BarChartDataSet?
        if itemSelectionList.onlyOneCategorySelected() {
            // il y a un seule catégorie de sélectionnée, afficher le détail
            if let categoryName = itemSelectionList.firstCategorySelected() {
                aDataSet = socialAccounts.getCashFlowCategoryStackedBarChartDataSet(
                    categoryName           : categoryName,
                    expenses               : expenses,
                    selectedExpenseCategory: selectedExpenseCategory)
            } else {
                customLog.log(level: .error,
                              "CashFlowStackedBarChartView : aDataSet = nil => graphique vide")
                aDataSet = nil
            }
        } else {
            // il y a plusieurs catégories sélectionnées, afficher le graphe résumé par catégorie
            aDataSet = socialAccounts.getCashFlowStackedBarChartDataSet(
                combination       : combination,
                itemSelectionList : itemSelectionList)
        }

        // ajouter les data au graphique
        let data = BarChartData(dataSet: ((aDataSet == nil ? BarChartDataSet() : aDataSet)!))
        data.setValueTextColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // ajouter le dataset au graphique
        chartView.data = data

        chartView.data?.notifyDataChanged()
    }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BarChartView {
        // créer et configurer un nouveau bar graph
        let chartView = BarChartView(title               : "Revenus / Dépenses",
                                     smallLegend         : false,
                                     axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))

        CashFlowStackedBarChartView.uiView = chartView
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

        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)
        uiView.notifyDataSetChanged()
    }
}

// MARK: - Preview
struct CashFlowDetailedChartView_Previews: PreviewProvider {
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
                NavigationLink(destination :CashFlowDetailedChartView()
                                .environmentObject(simulation)
                                .environmentObject(uiState)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                ) {
                    Text("Cash Flow Détaillé")
                }
                .isDetailLink(true)
            }
        }
    }
}
