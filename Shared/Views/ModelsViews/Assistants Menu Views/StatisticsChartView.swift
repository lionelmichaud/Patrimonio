//
//  StatisticsCharts.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 27/09/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Statistics
import Charts // https://github.com/danielgindi/Charts.git
import HelpersView

struct StatisticsChartsView: View {
    @State private var rgType: RandomGeneratorEnum = .uniform
    
    var body: some View {
        VStack {
            // sélecteur: Actif / Passif / Tout
            CasePicker(pickedCase: $rgType, label: "")
                .padding(.horizontal)
                .pickerStyle(.segmented)
            switch rgType {
                case .uniform:
                    UniformDistributionView()
                    
                case .discrete:
                    DiscreteDistributionView()
                    
                case .beta:
                    BetaDistributionView()
            }
        }
        .navigationTitle("Fonctions de Distribution")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct StatisticsChartsView_Previews: PreviewProvider {
    static var previews: some View {
        StatisticsChartsView()
    }
}
