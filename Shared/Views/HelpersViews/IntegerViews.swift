//
//  IntegerViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI

// MARK: - Saisie d'un Integer

struct IntegerEditView: View {
    let label            : String
    let comment          : String?
    @Binding var integer : Int
    
    var body: some View {
        let numberFormatter = NumberFormatter()
        let textValueBinding = Binding<String>(
            get: {
                String(integer)
            },
            set: {
                if let value = numberFormatter.number(from: $0) {
                    self.integer = value.intValue
                }
            })
        
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("entier",
                      text: textValueBinding)
                //.textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(maxWidth: 88)
                .numbersAndPunctuationKeyboardType()
                .multilineTextAlignment(.trailing)
        }
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    init(label   : String,
         comment : String? = nil,
         integer : Binding<Int>) {
        self.label   = label
        self.comment = comment
        _integer     = integer
    }
}

// MARK: - Affichage d'un Integer

struct IntegerView: View {
    let label   : String
    let integer : Int
    let weight  : Font.Weight
    let comment : String?
    
    var body: some View {
        HStack {
            Text(label)
                .fontWeight(weight)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(String(integer))
                .fontWeight(weight)
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    init(label: String, integer: Int, weight: Font.Weight = .regular, comment: String? = nil) {
        self.label   = label
        self.integer = integer
        self.weight  = weight
        self.comment = comment
    }
}

// MARK: - Previews

struct IntegerViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            IntegerView(label: "Label", integer: 4)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("IntegerView")
            IntegerEditView(label: "Label", integer: .constant(4))
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("IntegerEditView")
        }
        .previewDevice("iPhone 12")
    }
}

// MARK: - Library Views

struct IntegerViews_Library: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        let integer = 4
        LibraryItem(IntegerView(label: "Label", integer: integer),
                    title: "Integer View",
                    category: .control,
                    matchingSignature: "intview")
        LibraryItem(IntegerEditView(label: "Label", integer: .constant(4)),
                    title: "Integer Edit View",
                    category: .control,
                    matchingSignature: "inteditview")
    }
}
