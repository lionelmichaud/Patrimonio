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
import Files
import ModelEnvironment
import Persistence
import LifeExpense
import PatrimoineModel
import FamilyModel

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "UI.BalanceSheetGlobalChartView")

// MARK: - Balance Sheet Charts Views

/// Vue globale du bilan: Actif / Passif / Net
struct BalanceSheetGlobalChartView: View {
    @EnvironmentObject var dataStore  : Store
    @EnvironmentObject var family     : Family
    @EnvironmentObject var simulation : Simulation
    @EnvironmentObject var uiState    : UIState
    @State private var lifeEventChatIsPresented = false
    var lastYear: Int? { simulation.socialAccounts.balanceArray.last?.year }
    @State private var showInfoPopover = false
    let popOverTitle   = "Contenu du graphique:"
    let popOverMessage =
        """
        Evolution dans le temps des valeurs de l'ensemble des biens (actif et passif).
        détenus par l'ensemble des membres de la famille.
        Evolution du solde net.
        
        Lorsque la Famille est sélectionnée, tous les biens sont incorporés pour leur valeur globale.

        Les biens incorporés sont filtrés et évalués selon les préférences graphiques (Bilan) ⚙️.

        Utiliser le bouton 📷 pour placer une copie d'écran dans votre album photo.
        """
    
    var body: some View {
        GeometryReader { geometry in
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
                
                // graphique Bilan
                BalanceSheetLineChartView(for           : uiState.bsChartState.nameSelection,
                                          socialAccounts: $simulation.socialAccounts,
                                          title         : simulation.title)
                    .padding(.trailing, 4)

                // Graphique Evénement de Vie
                if lifeEventChatIsPresented {
                    FamilyLifeEventChartView(endDate: lastYear ?? Date.now.year + 30)
                        .frame(minHeight: 0, idealHeight: 100, maxHeight: geometry.size.height/4.0, alignment: .center)
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
                Button(action: { BalanceSheetLineChartView.saveImage(to: dataStore.activeDossier!.folder!) },
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

/// Wrapper de LineChartView
struct BalanceSheetLineChartView: NSUIViewRepresentable {

    // MARK: - Type Properties

    static var titleStatic : String = "image"
    static var uiView      : LineChartView?
    static var snapshotNb  : Int    = 0

    // MARK: - Properties

    @Binding var socialAccounts : SocialAccounts
    var personSelection         : String

    // MARK: - Initializer

    internal init(for thisName   : String,
                  socialAccounts : Binding<SocialAccounts>,
                  title          : String) {
        BalanceSheetLineChartView.titleStatic = title
        self.personSelection                  = thisName
        self._socialAccounts                  = socialAccounts
    }

    // MARK: - Type methods

    /// Sauvegarde de l'image en fichier  et dans l'album photo au format .PNG
    static func saveImage(to folder: Folder) {
        guard let chartView = BalanceSheetLineChartView.uiView else {
            #if DEBUG
            print("error: no chartView to save")
            #endif
            return
        }
        // construire l'image
        guard let image = chartView.getChartImage(transparent: false) else {
            #if DEBUG
            print("error: no image to save")
            #endif
            return
        }

        // sauvegarder l'image dans l'album photo
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)

        // sauvegarder l'image dans le répertoire documents/image
        let fileName = "Bilan-" + String(BalanceSheetLineChartView.snapshotNb) + ".png"
        do {
            try PersistenceManager.saveToImagePath(to              : folder,
                                                   fileName        : fileName,
                                                   simulationTitle : titleStatic,
                                                   image           : image)
        } catch {
            // do nothing
        }
        BalanceSheetLineChartView.snapshotNb += 1
    }

    // MARK: - Methods
    
    func updateData(of chartView: LineChartView) {
        // créer les DataSet: LineChartDataSets
        let dataSets =
            LineChartBalanceSheetVisitor(
                element         : socialAccounts.balanceArray,
                personSelection : personSelection)
            .dataSets
        
        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)
        data.setValueFormatter(DefaultValueFormatter(formatter: valueKiloFormatter))

        // ajouter le Chartdata au ChartView
        chartView.data = data
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

        // animer la transition
        uiView.animate(yAxisDuration: 0.5, easingOption: .linear)
        
        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

// MARK: - Preview

struct BalanceSheetGlobalChartView_Previews: PreviewProvider {
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
                NavigationLink(destination : BalanceSheetGlobalChartView()
                                .environmentObject(uiState)
                                .environmentObject(dataStore)
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
