//
//  PercentViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Saisie d'un pourcentage %

/// Affichage d'un pourcentage % [0% ... 100%]
/// - Parameters:
///   - label: libellé
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
///   - percent: valeur
public struct PercentEditView2: View {
    private let label       : String
    private let comment     : String?
    private let validity    : DoubleValidityRule
    @Binding
    private var percent     : Double // [0% ... 100%]
    @State
    private var textPercent : String
    
    public var body: some View {
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
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("montant",
                      text: textValueBinding)
                //.textFieldStyle(.roundedBorder)
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
        .textFieldStyle(.roundedBorder)
        .foregroundColor(validity.isValid(number: percent) ? .primary : .red)
    }
    
    /// Création
    /// - Parameters:
    ///   - label: libellé
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    ///   - percent: valeur
    public init(label    : String,
                comment  : String?  = nil,
                percent  : Binding<Double>,
                validity : DoubleValidityRule = .none) {
        self.label  = label
        self.comment = comment
        self.validity = validity
        _percent     = percent
        _textPercent = State(initialValue: String(percent.wrappedValue).replacingOccurrences(of: ".", with: ","))
    }
}

/// Affichage d'un pourcentage % [0% ... 100%]
/// - Parameters:
///   - label: libellé
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
///   - percent: valeur [0% ... 100%]
public struct PercentEditView: View {
    private let label    : String
    private let comment  : String?
    private let validity : DoubleValidityRule
    @Binding
    private var percent  : Double // [0% ... 100%]
    private let digit    : Int

    public var body: some View {
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("montant",
                      value: $percent,
                      format: .number.precision(.fractionLength(digit)))
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 88)
            .numbersAndPunctuationKeyboardType()
            Text("%")
        }
        .foregroundColor(validity.isValid(number: percent) ? .primary : .red)
    }

    /// Création
    /// - Parameters:
    ///   - label: libellé
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    ///   - percent: valeur [0% ... 100%]
    public init(label    : String,
                comment  : String?            = nil,
                percent  : Binding<Double>,
                digit    : Int                = 2,
                validity : DoubleValidityRule = .none) {
        self.label    = label
        self.comment  = comment
        _percent      = percent
        self.digit    = digit
        self.validity = validity
    }
}

/// Affichage d'un pourcentage % [0 ... 1]
/// - Parameters:
///   - label: libellé
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
///   - percent: valeur [0 ... 1]
///   - digit: Nombre de chifrre après la virgule à afficher
public struct PercentNormEditView: View {
    private let label    : String
    private let comment  : String?
    private let validity : DoubleValidityRule
    @Binding
    private var percent  : Double // [0 ... 1]
    private let digit    : Int

    public var body: some View {
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("montant",
                      value: $percent,
                      format: .percent.precision(.fractionLength(digit)))
            .multilineTextAlignment(.trailing)
            .textFieldStyle(.roundedBorder)
            .frame(maxWidth: 88)
            .numbersAndPunctuationKeyboardType()
        }
        .foregroundColor(validity.isValid(number: percent) ? .primary : .red)
    }

    /// Création
    /// - Parameters:
    ///   - label: libellé
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    ///   - percent: valeur [0 ... 1]
    ///   - digit: Nombre de chifrre après la virgule à afficher
    public init(label    : String,
                comment  : String?            = nil,
                percent  : Binding<Double>,
                digit    : Int                = 2,
                validity : DoubleValidityRule = .none) {
        self.label    = label
        self.comment  = comment
        _percent      = percent
        self.digit    = digit
        self.validity = validity
    }
}

// MARK: - Affichage d'un pourcentage %

/// Affichage d'un pourcentage % [0.0 ... 1.0]
/// - Parameters:
///   - label: Libellé à gauche
///   - percent: valeure numérique à afficher à droite
///   - digit: Nombre de chifrre après la virgule à afficher
///   - weight: Taille de la police utilisée pour `label` et `amount`
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
public struct PercentNormView: View {
    private let label   : String
    private let percent : Double // [0.0 ... 1.0]
    private let digit   : Int
    private let weight  : Font.Weight
    private let comment : String?
    
    public var body: some View {
        HStack {
            Text(label)
                .fontWeight(weight)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            Text(percent.percentNormString(digit: digit))
                .fontWeight(weight)
                .frame(maxWidth: 100, alignment: .trailing)
        }
    }
    
    /// - Parameters:
    ///   - label: Libellé à gauche
    ///   - percent: valeure numérique à afficher à droite
    ///   - digit: Nombre de chifrre après la virgule à afficher
    ///   - weight: Taille de la police utilisée pour `label` et `amount`
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    public init(label   : String,
                percent : Double,
                digit   : Int         = 2,
                weight  : Font.Weight = .regular,
                comment : String?     = nil) {
        self.label   = label
        self.percent = percent
        self.digit   = digit
        self.weight  = weight
        self.comment = comment
    }
}

/// Affichage d'un pourcentage % [0% ... 100%]
/// - Parameters:
///   - label: Libellé à gauche
///   - percent: valeure numérique à afficher à droite
///   - digit: Nombre de chifrre après la virgule à afficher
///   - weight: Taille de la police utilisée pour `label` et `amount`
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
public struct PercentView: View {
    private let label   : String
    private let percent : Double // [0% ... 100%]
    private let digit   : Int
    private let weight  : Font.Weight
    private let comment : String?
    
    public var body: some View {
        PercentNormView(label   : label,
                        percent : percent / 100.0,
                        digit   : digit,
                        weight  : weight,
                        comment : comment)
    }

    /// - Parameters:
    ///   - label: Libellé à gauche
    ///   - percent: valeure numérique à afficher à droite
    ///   - digit: Nombre de chifrre après la virgule à afficher
    ///   - weight: Taille de la police utilisée pour `label` et `amount`
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    public init(label   : String,
                percent : Double,
                digit   : Int         = 2,
                weight  : Font.Weight = .regular,
                comment : String?     = nil) {
        self.label   = label
        self.percent = percent
        self.digit   = digit
        self.weight  = weight
        self.comment = comment
    }
}

// MARK: - Previews

struct PercentViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PercentNormView(label   : "Label",
                            percent : 0.04123,
                            digit   : 1,
                            weight  : .bold,
                            comment : "Comment")
                .padding()
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentNormView")
            
            PercentView(label   : "Label",
                        percent : 4.123,
                        digit   : 1,
                        weight  : .bold,
                        comment : "Comment")
                .padding()
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentNormView")
            
            PercentEditView(label   : "Label",
                            comment : "Comment",
                            percent : .constant(4.9876))
                .padding()
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("PercentEditView")
        }
    }
}

// MARK: - Library Views

struct PercentViews_Library: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        let percent = 4.0
        LibraryItem(PercentNormView(label: "Label", percent: percent),
                    title: "Percent View",
                    category: .control,
                    matchingSignature: "pctview")
        LibraryItem(PercentEditView(label: "Label", percent: .constant(4.9)),
                    title: "Percent Edit View",
                    category: .control,
                    matchingSignature: "pcteditview")
    }
}
