//
//  BetaDistributionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import SwiftUI
import Statistics
import Charts // https://github.com/danielgindi/Charts.git

// MARK: - Loie Beta

struct BetaDistributionView: View {
    @State private var minX  : Double = 0.0
    @State private var maxX  : Double = 10.0
    @State private var alpha : Double = 2.0
    @State private var beta  : Double = 2.0
    let minmin =  0.0
    let maxmax = 10.0
    let delta  =  0.1

    var body: some View {
        VStack {
            HStack {
                VStack {
                    HStack {
                        Text("\(minX, specifier: "%.1f") [")
                            .frame(width: 70)
                        Slider(value             : $minX,
                               in                : minmin...maxmax,
                               step              : 0.1,
                               onEditingChanged  : { _ in maxX = max(minX+delta, maxX) },
                               minimumValueLabel : Text("\(minmin, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(maxmax, specifier: "%.1f")"),
                               label             : {Text("Minimum")})
                    }
                    .padding(.horizontal)
                    HStack {
                        Text("\(maxX, specifier: "%.1f") ]")
                            .frame(width: 70)
                        Slider(value             : $maxX,
                               in                : minmin...maxmax,
                               step              : 0.1,
                               onEditingChanged  : { _ in minX = min(minX, maxX-delta) },
                               minimumValueLabel : Text("\(minmin, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(maxmax, specifier: "%.1f")"),
                               label             : {Text("Maximum")})
                    }
                    .padding(.horizontal)
                }
                VStack {
                    HStack {
                        Text("\(alpha, specifier: "%.1f") alpha")
                            .frame(width: 70)
                        Slider(value             : $alpha,
                               in                : 0...10,
                               step              : 0.1,
                               minimumValueLabel : Text("\(0.0, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(10.0, specifier: "%.1f")"),
                               label             : {Text("alpha")})
                    }
                    .padding(.horizontal)
                    HStack {
                        Text("\(beta, specifier: "%.1f") beta")
                            .frame(width: 70)
                        Slider(value             : $beta,
                               in                : 0...10,
                               step              : 0.1,
                               minimumValueLabel : Text("\(0.0, specifier: "%.1f")"),
                               maximumValueLabel : Text("\(10.0, specifier: "%.1f")"),
                               label             : {Text("beta")})
                    }
                    .padding(.horizontal)
                }
            }
            BetaGammaAssistantView(minX  : $minX, maxX : $maxX,
                                   alpha : $alpha, beta : $beta)

        }
    }
}

struct BetaGammaAssistantView : UIViewRepresentable {
    @Binding var minX : Double
    @Binding var maxX : Double
    @Binding var alpha: Double
    @Binding var beta : Double
    static var uiView : LineChartView?

    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title               : "Distribution Beta",
                                      axisFormatterChoice : AxisFormatterChoice.percent)

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)

        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        BetaGammaAssistantView.uiView = chartView
        return chartView
    }

    func updateUIView(_ uiView: LineChartView, context: Context) {
        guard maxX > minX else { return }
        uiView.clear()
        //uiView.data?.clearValues()

        // créer les DataSet: LineChartDataSets
        let dataSets = getBetaGammaLineChartDataSets(minX : minX, maxX: maxX,
                                                     alpha: alpha, beta: beta)

        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: CGFloat(12.0))!)

        // ajouter le Chartdata au ChartView
        uiView.data = data

        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

func getBetaGammaLineChartDataSets(minX : Double,
                                   maxX : Double,
                                   alpha: Double,
                                   beta : Double) -> [LineChartDataSet]? {

    let nbSamples = 300

    //: ### ChartDataEntry

    /// fonction gamma
    //    let yVals1 = functionSampler(minX: minX, maxX: maxX, nbSamples: nbSamples, f: tgamma).map {
    //        ChartDataEntry(x: $0.x, y: $0.y)
    //    }

    /// générateur de nombre aléatoire suivant une distribution Beta
    var betaGenerator = BetaRandomGenerator(minX  : minX,
                                            maxX  : maxX,
                                            alpha : alpha,
                                            beta  : beta)
    betaGenerator.initialize()
    
    /// PDF de la distribution Beta(alpha,beta)
    let yVals1 = numericFunctionSampler(minX      : minX,
                                        maxX      : maxX,
                                        nbSamples : nbSamples,
                                        f         : betaGenerator.pdf).map {
                                            ChartDataEntry(x: $0.x, y: $0.y)
                                        }
    
    /// CDF de la distribution Beta(alpha,beta)
    var yVals2 = [ChartDataEntry]()
    if let betaCdfCurve = betaGenerator.cdfCurve {
        betaCdfCurve.forEach { point in
            yVals2.append(ChartDataEntry(x: point.x, y: point.y))
        }
    }
    
    /// tirages aléatoires selon distribution en Beta et ajout à un histogramme
    let nbRandomSamples = 1000
    let sequence = betaGenerator.sequence(of: nbRandomSamples)
    var histogram = Histogram(distributionType : .continuous,
                              openEnds         : false,
                              Xmin             : minX,
                              Xmax             : maxX,
                              bucketNb         : 50)
    histogram.record(sequence)
    
    /// PDF des tirages aléatoires
    var yVals3 = [ChartDataEntry]()
    histogram.xPDF.forEach {
        yVals3.append(ChartDataEntry(x: $0.x, y: $0.p))
    }

    /// CDF des tirages aléatoires
    var yVals4 = [ChartDataEntry]()
    histogram.xCDF.forEach {
        yVals4.append(ChartDataEntry(x: $0.x, y: $0.p))
    }

    let set1 = LineChartDataSet(entries: yVals1,
                                label: "PDF de Beta (\(alpha), \(beta))",
                                color: #colorLiteral(red: 1, green: 0.1491314173, blue: 0, alpha: 1))
    let set2 = LineChartDataSet(entries: yVals2,
                                label: "CDF de Beta (\(alpha), \(beta))",
                                color: #colorLiteral(red: 0.1960784346, green: 0.3411764801, blue: 0.1019607857, alpha: 1))
    let set3 = LineChartDataSet(entries: yVals3,
                                label: "PDF des tirages aléatoires",
                                color: #colorLiteral(red: 0.9411764741, green: 0.4980392158, blue: 0.3529411852, alpha: 1))
    let set4 = LineChartDataSet(entries: yVals4,
                                label: "CDF des tirages aléatoires",
                                color: #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1))

    // ajouter les dataSet au dataSets
    var dataSets = [LineChartDataSet]()
    dataSets.append(set1)
    dataSets.append(set2)
    dataSets.append(set3)
    dataSets.append(set4)

    return dataSets
}

func numericFunctionSampler (minX: Double, maxX: Double, nbSamples: Int, f: (Double) -> Double) -> [(x: Double, y: Double)] {
    var xy = [(x: Double, y: Double)]()
    for i in 1...nbSamples {
        let x :Double = min(minX + (maxX - minX) / nbSamples.double() * i.double(), maxX)
        xy.append((x, f(x)))
    }
    return xy
}

struct BetaDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        BetaDistributionView()
    }
}
