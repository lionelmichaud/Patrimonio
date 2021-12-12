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
import Files
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel
import CashFlow

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.CashFlowDetailedChartView")

// MARK: - Cash Flow Detailed Charts Views

/// Vue détaillée du cash flow: Revenus / Dépenses / Net
struct CashFlowDetailedChartView: View {
    @EnvironmentObject var dataStore  : Store
    @EnvironmentObject var family     : Family
    @EnvironmentObject var expenses   : LifeExpensesDic
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
                    // sélecteur: Adults / Enfants
                    Picker(selection: self.$uiState.cfChartState.parentChildrenSelection, label: Text("Personne")) {
                        Text(AppSettings.shared.adultsLabel)
                            .tag(AppSettings.shared.adultsLabel)
                        Text(AppSettings.shared.childrenLabel)
                            .tag(AppSettings.shared.childrenLabel)
                    }
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // sélecteur: Actif / Passif / Tout
                    CasePicker(pickedCase: self.$uiState.cfChartState.combination, label: "")
                        .padding(.horizontal)
                        .pickerStyle(SegmentedPickerStyle())
                    if self.uiState.cfChartState.itemSelection.onlyOneCategorySelected() {
                        if let categoryName = self.uiState.cfChartState.itemSelection.firstSelectedCategory() {
                            if categoryName == "Dépenses de vie" {
                                CasePicker(pickedCase: $uiState.cfChartState.selectedExpenseCategory, label: "Catégories de dépenses")
                                    .pickerStyle(SegmentedPickerStyle())
                                    .padding(.horizontal)
                            }
                        }
                    }
                    // graphique Cash-Flow
                    CashFlowStackedBarChartView(for           : uiState.cfChartState.parentChildrenSelection,
                                                socialAccounts: self.$simulation.socialAccounts,
                                                title         : self.simulation.title,
                                                combination   : self.uiState.cfChartState.combination,
                                                itemSelection : self.uiState.cfChartState.itemSelection,
                                                expenses      : expenses,
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
        .toolbar(content: myToolBarContent)
    }
    
    @ToolbarContentBuilder
    func myToolBarContent() -> some ToolbarContent {
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
            Button(action: { CashFlowStackedBarChartView.saveImage(to: dataStore.activeDossier!.folder!) },
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

// MARK: - Wrappers de UIView

struct CashFlowStackedBarChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : BarChartView?
    static var snapshotNb  : Int    = 0

    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var combination             : CashCombination
    var parentChildrenSelection : String
    var itemSelectionList       : ItemSelectionList
    var expenses                : LifeExpensesDic
    var selectedExpenseCategory : LifeExpenseCategory?

    // MARK: - Initializer

    internal init(for parentChildrenSelection : String,
                  socialAccounts              : Binding<SocialAccounts>,
                  title                       : String,
                  combination                 : CashCombination,
                  itemSelection               : ItemSelectionList,
                  expenses                    : LifeExpensesDic,
                  selectedExpenseCategory     : LifeExpenseCategory?  = nil) {
        CashFlowStackedBarChartView.titleStatic = title
        self.parentChildrenSelection = parentChildrenSelection
        self.combination             = combination
        self.itemSelectionList       = itemSelection
        self.expenses                = expenses
        self.selectedExpenseCategory = selectedExpenseCategory
        self._socialAccounts         = socialAccounts
    }

    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
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
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        CashFlowStackedBarChartView.snapshotNb += 1
    }

    // MARK: - Methods

    func updateData(of chartView: BarChartView) {
        //: ### BarChartData
        let aDataSet : BarChartDataSet?
        if itemSelectionList.onlyOneCategorySelected() {
            // il y a un seule catégorie de sélectionnée, afficher le détail des items de la catégorie
            if let categoryName = itemSelectionList.firstSelectedCategory() {
                aDataSet = CategoryBarChartCashFlowVisitor(
                    element                 : socialAccounts.cashFlowArray,
                    personSelection         : parentChildrenSelection,
                    categoryName            : categoryName,
                    expenses                : expenses,
                    selectedExpenseCategory : selectedExpenseCategory).dataSet
            } else {
                customLog.log(level: .error,
                              "CashFlowStackedBarChartView : aDataSet = nil => graphique vide")
                aDataSet = nil
            }
        } else {
            // il y a plusieurs catégories sélectionnées, afficher le graphe résumé par catégorie
            aDataSet = BarChartCashFlowVisitor(
                element           : socialAccounts.cashFlowArray,
                personSelection   : parentChildrenSelection,
                combination       : combination,
                itemSelectionList : itemSelectionList).dataSet
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
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var dataStore  = Store()
    static var family     = Family( )
    static var expenses   = LifeExpensesDic()
    static var patrimoine = Patrimoin()
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
                NavigationLink(destination :CashFlowDetailedChartView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("Cash Flow Détaillé")
                }
                .isDetailLink(true)
            }
        }
    }
}
