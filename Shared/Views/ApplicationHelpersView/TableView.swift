//
//  TableView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 01/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation
import HelpersView
import ChartsExtensions

struct ListTableRowView<RatingView1: View, RatingView2: View>: View {
    private let label       : String
    private let value       : Double
    private let indentLevel : Int
    private let header      : Bool
    private var rating1     : RatingView1
    private var rating2     : RatingView2

    public init(label                : String,
                value                : Double,
                indentLevel          : Int,
                header               : Bool,
                @ViewBuilder rating1 : () -> RatingView1,
                @ViewBuilder rating2 : () -> RatingView2) {
        self.label       = label
        self.value       = value
        self.indentLevel = indentLevel
        self.header      = header
        self.rating1     = rating1()
        self.rating2     = rating2()
    }

    var body: some View {
        HStack {
            if header {
                Image(systemName: "chevron.down")
                Text(label)
                    .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                      design: Font.Design.default))
                    .fontWeight(.bold)
                
            } else {
                Text(label)
                    .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                      design: Font.Design.default))
            }
            Spacer()
            rating1.padding(.trailing)
            rating2
            Text(value.€String)
                .font(Font.system(size: ListTheme[indentLevel].valueFontSize,
                                  design: Font.Design.default))
                .frame(width: 150)
        }
            .padding(EdgeInsets(top: 0,
                                leading: ListTheme[indentLevel].indent,
                                bottom: 0,
                                trailing: 0))
            .listRowBackground(ListTheme.tableRowsBaseColor.opacity(header ? ListTheme[indentLevel].opacity:0.0))
    }
}

struct TableView_Previews: PreviewProvider {
    static var previews: some View {
        ListTableRowView(label: "Titre",
                         value: 12345,
                         indentLevel: 0,
                         header: true,
                         rating1: { RatingView(rating    : 1,
                                               minRating : 0,
                                               maxRating : 4,
                                               label     : "Risque",
                                               font      : .footnote,
                                               offColor  : Color.gray,
                                               onColor   : ChartThemes.riskColorsTable.map { Color($0) },
                                               offImage  : Image(systemName : "square"),
                                               onImage   : Image(systemName : "square.fill"))
        },
                         rating2: { RatingView(rating    : 2,
                                               minRating : 0,
                                               maxRating : 2,
                                               label     : "Liquidité",
                                               font      : .footnote,
                                               offColor  : Color.gray,
                                               onColor   : ChartThemes.liquidityColorsTable.map { Color($0) },
                                               offImage  : Image(systemName : "square"),
                                               onImage   : Image(systemName : "square.fill"))
        })
            .previewLayout(.fixed(width: 700, height: /*@START_MENU_TOKEN@*/50.0/*@END_MENU_TOKEN@*/))
    }
}
