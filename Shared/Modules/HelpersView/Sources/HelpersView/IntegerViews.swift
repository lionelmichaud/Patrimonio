//
//  IntegerViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Saisie d'un Integer

public struct IntegerEditView2: View {
    private let label    : String
    private let comment  : String?
    private let validity : IntegerValidityRule
    @Binding
    private var integer : Int

    public var body: some View {
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
                //.textFieldStyle(.roundedBorder)
                .frame(maxWidth: 88)
                .numbersAndPunctuationKeyboardType()
                .multilineTextAlignment(.trailing)
        }
        .textFieldStyle(.roundedBorder)
        .foregroundColor(validity.isValid(number: integer) ? .primary : .red)
    }

    public init(label    : String,
                comment  : String?            = nil,
                integer  : Binding<Int>,
                validity : IntegerValidityRule = .none) {
        self.label    = label
        self.comment  = comment
        self.validity = validity
        _integer      = integer
    }
}

/// Saisie d'un nombre Entier
/// - Parameters:
///   - label: libellé
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
///   - integer: valeur entière
///
/// - Note: [Reference](https://github.com/nsscreencast/397-swiftui-tip-calculator/blob/master/TipCalculator/TipCalculator/ContentView.swift)
///
public struct IntegerEditView: View {
    private let label    : String
    private let comment  : String?
    private let validity : IntegerValidityRule
    @Binding
    private var integer : Int

    public var body: some View {
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("entier", value: $integer, format: .number.precision(.fractionLength(0)))
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 88)
            .numbersAndPunctuationKeyboardType()
        }
        .foregroundColor(validity.isValid(number: integer) ? .primary : .red)
    }

    public init(label    : String,
                comment  : String?            = nil,
                integer  : Binding<Int>,
                validity : IntegerValidityRule = .none) {
        self.label    = label
        self.comment  = comment
        _integer      = integer
        self.validity = validity
    }
}

// MARK: - Affichage d'un Integer

public struct IntegerView: View {
    private let label   : String
    private let integer : Int
    private let weight  : Font.Weight
    private let comment : String?
    
    public var body: some View {
        HStack {
            Text(label)
                .fontWeight(weight)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(integer, format: .number.precision(.fractionLength(0)))
                .fontWeight(weight)
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    public init(label   : String,
                integer : Int,
                weight  : Font.Weight = .regular,
                comment : String?     = nil) {
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
                .padding()
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("IntegerView")
            IntegerEditView(label: "Label", integer: .constant(4))
                .padding()
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
