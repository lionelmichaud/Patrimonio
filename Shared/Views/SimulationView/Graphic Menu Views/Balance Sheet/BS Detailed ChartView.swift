//
//  BS Detailed ChartView.swift
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
import BalanceSheet

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.BalanceSheetDetailedChartView")

// MARK: - Balance Sheet Detailed Charts Views

/// Vue détaillée du bilan: Actif / Passif / Tout
struct BalanceSheetDetailedChartView: View {
    @EnvironmentObject var dataStore : Store
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var lifeEventChatIsPresented = false
    @State private var menuIsPresented = false
    let menuWidth: CGFloat = 200
    var lastYear: Int? { simulation.socialAccounts.balanceArray.last?.year }
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage = """
        Evolution dans le temps des valeurs de l'ensemble des biens (actif et passif) détenus
        par l'ensemble des membres de la famille ou par un individu en particulier.
        Evolution du solde net.

        Lorsque la Famille est sélectionnée, tous les biens sont incorporés pour leur valeur globale.

        Lorsque les Parents sont sélectionnés, les biens incorporés sont définis dans les préférences KPI ⚙️
        et sont évalués à leur valeur possédée (patrimoniale).

        Lorsqu'un seul individu est sélectionné, les biens sont évalués selon une méthode
        et selon un filtre définis dans les préférences graphiques ⚙️.

        Utiliser la loupe 🔍 pour filtrer les catégories d'actif / passif.
        Utiliser le bouton 🔳 pour faire apparaître un second grahique présentant l'ordre chronologique
         des événemnts de vie de chaque membre de la famille
        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                /// zone de graphique
                VStack {
                    // sélecteur: Membre de la famille / Tous
                    Picker(selection: self.$uiState.bsChartState.nameSelection, label: Text("Personne")) {
                        ForEach(family.members.items.sorted(by: < )) { person in
                            PersonNameRow(member: person)
                        }
                        Text(AppSettings.shared.adultsLabel)
                            .tag(AppSettings.shared.adultsLabel)
                        Text(AppSettings.shared.allPersonsLabel)
                            .tag(AppSettings.shared.allPersonsLabel)
                    }
                    .padding(.horizontal)
                    .pickerStyle(SegmentedPickerStyle())

                    // sélecteur: Actif / Passif / Tout
                    CasePicker(pickedCase: self.$uiState.bsChartState.combination, label: "")
                        .padding(.horizontal)
                        .pickerStyle(SegmentedPickerStyle())

                    // graphique Bilan
                    BalanceSheetStackedBarChartView(for           : uiState.bsChartState.nameSelection,
                                                    socialAccounts: $simulation.socialAccounts,
                                                    title         : simulation.title,
                                                    combination   : uiState.bsChartState.combination,
                                                    itemSelection : uiState.bsChartState.itemSelection)
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
                    MenuContentView(itemSelection: self.$uiState.bsChartState.itemSelection)
                        .frame(width: self.menuWidth)
                        .transition(.move(edge: .leading))
                }
            }
        }
        .navigationTitle("Bilan Détaillé")
        .navigationBarTitleDisplayModeInline()
        .toolbar {
            //  menu slideover de filtrage
            ToolbarItem(placement: .navigation) {
                Button(action: { withAnimation { self.menuIsPresented.toggle() } },
                       label: {
                        if self.uiState.bsChartState.itemSelection.allCategoriesSelected() {
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
                Button(action: { BalanceSheetStackedBarChartView.saveImage(to: dataStore.activeDossier!.folder!) },
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

struct BalanceSheetStackedBarChartView: UIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : BarChartView?
    static var snapshotNb  : Int    = 0

    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var combination             : BalanceCombination
    var personSelection         : String
    var itemSelectionList       : ItemSelectionList

    // MARK: - Initializer

    internal init(for thisName   : String,
                  socialAccounts : Binding<SocialAccounts>,
                  title          : String,
                  combination    : BalanceCombination,
                  itemSelection  : ItemSelectionList) {
        BalanceSheetStackedBarChartView.titleStatic = title
        self.combination       = combination
        self.personSelection   = thisName
        self.itemSelectionList = itemSelection
        self._socialAccounts   = socialAccounts
    }

    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard let chartView = BalanceSheetStackedBarChartView.uiView else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }
        /// construire l'image
        guard let image = chartView.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: nothing to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-detailed-" + String(BalanceSheetStackedBarChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        BalanceSheetStackedBarChartView.snapshotNb += 1
    }

    // MARK: - Methods

    func updateData(of chartView: BarChartView) {
        //: ### BarChartData
        let aDataSet : BarChartDataSet?
        if itemSelectionList.onlyOneCategorySelected() {
            // il y a un seule catégorie de sélectionnée, afficher le détail
            if let categoryName = itemSelectionList.firstSelectedCategory() {
                aDataSet = CategoryBarChartBalanceSheetVisitor(
                    element         : socialAccounts.balanceArray,
                    personSelection : personSelection,
                    categoryName    : categoryName,
                    combination     : combination)
                    .dataSet
            } else {
                customLog.log(level : .error,
                              "getBalanceSheetCategoryStackedBarChartDataSet : aDataSet = nil => graphique vide")
                aDataSet = nil
            }
        } else {
            // il y a plusieurs catégories sélectionnées, afficher le graphe résumé par catégorie
            aDataSet = BarChartBalanceSheetVisitor(
                element           : socialAccounts.balanceArray,
                personSelection   : personSelection,
                combination       : combination,
                itemSelectionList : itemSelectionList)
                .dataSet
        }

        // ajouter les data au graphique
        let data = BarChartData(dataSet: ((aDataSet == nil ? BarChartDataSet() : aDataSet)!))
        data.setValueTextColor(#colorLiteral(red: 1, green: 1, blue: 1, alpha: 1))
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // ajouter le dataset au graphique
        chartView.data = data
    }

    /// Création de la vue du Graphique
    /// - Parameter context:
    /// - Returns: Graphique View
    func makeUIView(context: Context) -> BarChartView {
        // créer et configurer un nouveau bar graphique
        let chartView = BarChartView(title               : "Actif / Passif",
                                     smallLegend         : false,
                                     axisFormatterChoice : .largeValue(appendix: "€", min3Digit: true))

        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        BalanceSheetStackedBarChartView.uiView = chartView
        return chartView
    }

    /// Mise à jour de la vue du Graphique
    /// - Parameters:
    ///   - uiView: Graphique View
    ///   - context:
    func updateUIView(_ uiView: BarChartView, context: Context) {
        uiView.clear()
        updateData(of: uiView)

        // animer la transition
        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)

        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

// MARK: - Preview

struct BalanceSheetDetailedChartView_Previews: PreviewProvider {
    static var model      = Model(fromBundle: Bundle.main)
    static var uiState    = UIState()
    static var dataStore  = Store()
    static var family     = try! Family(fromFolder: try! PersistenceManager.importTemplatesFromAppAndCheckCompatibility())
    static var expenses   = try! LifeExpensesDic(fromFolder: try! PersistenceManager.importTemplatesFromAppAndCheckCompatibility())
    static var patrimoine = try! Patrimoin(fromFolder: try! PersistenceManager.importTemplatesFromAppAndCheckCompatibility())
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
                NavigationLink(destination :BalanceSheetDetailedChartView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
                                .environmentObject(family)
                                .environmentObject(patrimoine)
                                .environmentObject(simulation)
                ) {
                    Text("Bilan Détaillé")
                }
                .isDetailLink(true)
            }
        }
    }
}
