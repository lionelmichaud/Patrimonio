//
//  PercentViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Saisie d'un pourcentage %

struct PercentEditView: View {
    private let label     : String
    @Binding var percent  : Double // [0% ... 100%]
    @State var textPercent: String
    
    var body: some View {
        let textValueBinding = Binding<String>(
            get: {
                self.textPercent
            },
            set: {
                self.textPercent = $0
                // actualiser la valeur numérique
                self.percent = Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0
            })
        
        return HStack {
            Text(label)
            Spacer()
            TextField("montant",
                      text: textValueBinding)
                //.textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 88)
                .decimalPadKeyboardType()
                .multilineTextAlignment(.trailing)
                .onChange(of: textPercent) { newValue in
                    // filtrer les caractères non numériques
                    var filtered = newValue.filter { ",-0123456789".contains($0) }
                    // filtrer `-` s'il n'est pas le premier caractère
                    if filtered.count > 0 {
                        filtered = filtered.replacingOccurrences(of: "-",
                                                                 with: "",
                                                                 range: filtered.index(filtered.startIndex, offsetBy: 1)..<filtered.endIndex)
                    }
                    if filtered != newValue {
                        self.textPercent = filtered
                    }
                }
            Text("%")
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    init(label: String, percent: Binding<Double>) {
        self.label  = label
        _percent     = percent
        _textPercent = State(initialValue: percent.wrappedValue.percentString(digit: 2))
    }
}

// MARK: - Affichage d'un pourcentage %

struct PercentView: View {
    let label   : String
    let percent : Double // [0.0 ... 1.0]
    let comment : String?
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(percentFormatter.string(from: percent as NSNumber) ?? "??")
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    init(label: String, percent : Double, comment: String? = nil) {
        self.label   = label
        self.percent = percent
        self.comment = comment
    }
}

// MARK: - Previews

struct PercentViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PercentView(label: "Label", percent: 4)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentView")
            PercentEditView(label: "Label", percent: .constant(4.9))
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentEditView")
        }
        .previewDevice("iPhone 12")
    }
}

// MARK: - Library Views

struct PercentViews_Library: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        let percent = 4.0
        LibraryItem(PercentView(label: "Label", percent: percent),
                    title: "Percent View",
                    category: .control,
                    matchingSignature: "pctview")
        LibraryItem(PercentEditView(label: "Label", percent: .constant(4.9)),
                    title: "Percent Edit View",
                    category: .control,
                    matchingSignature: "pcteditview")
    }
}
