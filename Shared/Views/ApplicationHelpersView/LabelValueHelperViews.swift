//
//  LabelValueHelpersView.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation

struct LabeledValueRowView: View {
    @Binding var colapse: Bool
    let label           : String
    let value           : Double
    let indentLevel     : Int
    let header          : Bool
    let icon            : Image
    
    var body: some View {
        HStack {
            if header {
                // bouton pour déplier / replier la liste
                Button(action: {
                    withAnimation(.easeInOut) {
                        self.colapse.toggle()
                    }
                },
                label: {
                    Image(systemName: "chevron.right")
                        .foregroundColor(.accentColor)
                        .rotationEffect(.degrees(colapse ? 0 : 90))
                        //.scaleEffect(colapse ? 1 : 1.5)
                })
                Text(label)
                    .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                      design: Font.Design.default))
                    .fontWeight(.bold)
                
            } else {
                HStack {
                    // symbol document en tête de ligne
                    icon.imageScale(.large)
                    //.font(Font.title.weight(.semibold))
                    Text(label)
                        .font(Font.system(size: ListTheme[indentLevel].labelFontSize,
                                          design: Font.Design.default))
                }
            }
            Spacer()
            Text(value.€String)
                .font(Font.system(size: ListTheme[indentLevel].valueFontSize,
                                  design: Font.Design.default))
        }
        .padding(EdgeInsets(top      : 0,
                            leading  : ListTheme[indentLevel].indent,
                            bottom   : 0,
                            trailing : 0))
        .listRowBackground(ListTheme.rowsBaseColor.opacity(header ? ListTheme[indentLevel].opacity:0.0))
    }

    init(colapse     : Binding<Bool>,
         label       : String,
         value       : Double,
         indentLevel : Int,
         header      : Bool,
         icon        : Image = Image(systemName: "doc")) {
        self._colapse    = colapse
        self.label       = label
        self.value       = value
        self.indentLevel = indentLevel
        self.header      = header
        self.icon        = icon
    }
}

// MARK: - Tests & Previews

struct TestView: View {
    var body: some View {
        List {
            LabeledValueRowView(colapse: .constant(false),
                                label: "Level 0",
                                value: 12345,
                                indentLevel: 0,
                                header: true)
            LabeledValueRowView(colapse: .constant(false),
                                label: "level 1",
                                value: 12345,
                                indentLevel: 1,
                                header: true)
            LabeledValueRowView(colapse: .constant(false),
                                label: "Level 2",
                                value: 12345,
                                indentLevel: 2,
                                header: true)
            LabeledValueRowView(colapse: .constant(false),
                                label: "Level 3",
                                value: 12345,
                                indentLevel: 3,
                                header: true)
            LabeledValueRowView(colapse: .constant(true),
                                label: "Level 4",
                                value: 12345,
                                indentLevel: 3,
                                header: false)
        }
    }
}

struct LabelValueHelpersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TestView().colorScheme(.dark)
                .previewDisplayName("LabeledValueRowView")
            TestView().colorScheme(.light)
                .previewDisplayName("LabeledValueRowView")
        }
        .previewDevice("iPhone 12")
    }
}
