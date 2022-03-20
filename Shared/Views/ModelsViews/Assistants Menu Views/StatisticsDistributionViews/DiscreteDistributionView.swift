//
//  DiscreteDistributionView.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 16/05/2021.
//

import SwiftUI
import Statistics
import Charts // https://github.com/danielgindi/Charts.git
import ChartsExtensions

// MARK: - Loie Discrete

struct DiscreteDistributionView: View {
    @State private var minX : Double = 0.0
    @State private var maxX : Double = 10.0
    let minmin =  0.0
    let maxmax = 10.0
    let delta  =  0.1

    var body: some View {
        VStack {
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
            DiscreteChartView(minX: $minX, maxX: $maxX)
        }
    }
}

struct DiscreteChartView : UIViewRepresentable {
    @Binding var minX : Double
    @Binding var maxX : Double
    static var uiView : LineChartView?

    func getDiscreteChartDataSets(minX : Double,
                                  maxX : Double) -> [LineChartDataSet]? {

        //: ### ChartDataEntry

        /// générateur de nombre aléatoire suivant une distribution Discrète
        var generator = DiscreteRandomGenerator(pdf: [[1.0, 0.2],
                                                      [3.0, 0.3],
                                                      [4.0, 0.4],
                                                      [6.0, 0.1]])

        /// tirages aléatoires selon distribution en Beta et ajout à un histogramme
        let nbRandomSamples = 1000
        let sequence  = generator.sequence(of: nbRandomSamples)
        var histogram = Histogram(distributionType : .discrete,
                                  openEnds         : false,
                                  Xmin             : minX,
                                  Xmax             : maxX,
                                  bucketNb         : 50)
        sequence.forEach {
            histogram.record($0)
        }

        return LineChartHistogramVisitor(element: histogram).dataSets
    }

    func makeUIView(context: Context) -> LineChartView {
        // créer et configurer un nouveau graphique
        let chartView = LineChartView(title              : "Distribution Discrète",
                                      axisFormatterChoice : AxisFormatterChoice.percent)

        // animer la transition
        chartView.animate(yAxisDuration: 0.5, easingOption: .linear)

        // mémoriser la référence de la vue pour sauvegarde d'image ultérieure
        DiscreteChartView.uiView = chartView
        return chartView
    }

    func updateUIView(_ uiView: LineChartView, context: Context) {
        guard maxX > minX else { return }
        uiView.clear()
        //uiView.data?.clearValues()

        // créer les DataSet: LineChartDataSets
        let dataSets = getDiscreteChartDataSets(minX: minX, maxX: maxX)

        // ajouter les DataSet au Chartdata
        let data = LineChartData(dataSets: dataSets)
        data.setValueTextColor(ChartThemes.DarkChartColors.valueColor)
        data.setValueFont(NSUIFont(name: "HelveticaNeue-Light", size: 12.0)!)

        // ajouter le Chartdata au ChartView
        uiView.data = data

        uiView.data?.notifyDataChanged()
        uiView.notifyDataSetChanged()
    }
}

struct DiscreteDistributionView_Previews: PreviewProvider {
    static var previews: some View {
        DiscreteDistributionView()
    }
}
