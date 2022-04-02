//
//  AmountViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Edition d'un montant en €

/// Saisie d'un montant en €
/// - Parameters:
///   - label: libellé
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
///   - amount: valeur
///   - currency: affiche le symbole € après la valeur si Vrai
public struct AmountEditView: View {
    private let label    : String
    private let comment  : String?
    private let currency : Bool
    private let validity : DoubleValidityRule
    @Binding
    private var amount   : Double
    @State
    private var text     : String
    private var textValueBinding : Binding<String> {
        Binding(
            get: {
                self.text
            },
            set: {
                self.text = $0
                // actualiser la valeur numérique
                self.amount = Double($0.replacingOccurrences(of: ",", with: ".")) ?? 0
            }
        )
    }
    
    public var body: some View {
        return HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("montant",
                      text: textValueBinding)
                .frame(maxWidth: 100)
                .numbersAndPunctuationKeyboardType()
                .multilineTextAlignment(.trailing)
                .onChange(of: text) { newText in
                    // filtrer les caractères non numériques
                    var filtered = newText.filter { ",-0123456789".contains($0) }
                    // filtrer `-` s'il n'est pas le premier caractère
                    if filtered.count > 0 {
                        filtered = filtered.replacingOccurrences(of: "-",
                                                                 with: "",
                                                                 range: filtered.index(filtered.startIndex, offsetBy: 1)..<filtered.endIndex)
                    }
                    if filtered != newText {
                        self.text = filtered
                    }
                }
                .onDisappear {
                    //                    print("Disappeared \(amount)")
                    text = String(amount).replacingOccurrences(of: ".", with: ",")
                }
            if currency {
                Text("€")
            }
        }
        .textFieldStyle(.roundedBorder)
        .foregroundColor(validity.isValid(number: amount) ? .primary : .red)
    }
    
    /// Création
    /// - Parameters:
    ///   - label: libellé
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    ///   - amount: valeur
    ///   - currency: affiche le symbole € après la valeur si Vrai
    public init(label    : String,
                comment  : String?  = nil,
                amount   : Binding<Double>,
                validity : DoubleValidityRule = .none,
                currency : Bool = true) {
        self.label    = label
        self.comment  = comment
        self.currency = currency
        self.validity = validity
        self._amount  = amount
        _text = State(initialValue: String(amount.wrappedValue).replacingOccurrences(of: ".", with: ","))
        //        print("created: value = \(amount); text = \(text)")
    }
}

// MARK: - Affichage d'un montant en €

/// Affichage d'un montant en €
/// - Parameters:
///   - label: Libellé à gauche
///   - amount: valeure numérique à afficher à droite
///   - digit: Nombre de chifrre après la virgule à afficher
///   - weight: Taille de la police utilisée pour `label` et `amount`
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
///   - kEuro: si Vrai alors affiche la valeur en k€ au lieu de €
public struct AmountView: View {
    private let label   : String
    private let amount  : Double
    private let digit   : Int
    private let kEuro   : Bool
    private let weight  : Font.Weight
    private let comment : String?
    
    public var body: some View {
        HStack {
            Text(label)
                .fontWeight(weight)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            if kEuro {
                Text(amount.k€String)
                    .fontWeight(weight)
                    .frame(maxWidth: 100, alignment: .trailing)
            } else {
                Text(amount.€String(digit: digit))
                    .fontWeight(weight)
                    .frame(maxWidth: 100, alignment: .trailing)
            }
        }
    }
    
    /// Création
    /// - Parameters:
    ///   - label: Libellé à gauche
    ///   - amount: valeure numérique à afficher à droite
    ///   - digit: Nombre de chifrre après la virgule à afficher
    ///   - weight: Taille de la police utilisée pour `label` et `amount`
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    ///   - kEuro: si Vrai alors affiche la valeur en k€ au lieu de €
    public init(label   : String,
                amount  : Double,
                kEuro   : Bool        = false,
                digit   : Int         = 0,
                weight  : Font.Weight = .regular,
                comment : String?     = nil) {
        self.label   = label
        self.amount  = amount
        self.kEuro   = kEuro
        self.digit   = digit
        self.weight  = weight
        self.comment = comment
    }
}

// MARK: - Previews

struct AmountViews_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AmountView(label   : "Label",
                       amount  : 1234.345,
                       digit   : 2,
                       weight  : .bold,
                       comment : "Comment")
                .preferredColorScheme(.dark)
                .padding(.all)
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("AmountView")
            AmountEditView(label: "Label",
                           comment: "Comment",
                           amount: .constant(1234.345))
                .preferredColorScheme(.dark)
                .padding(.all)
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("AmountEditView")
        }
    }
}

struct AmountEditView_Previews: PreviewProvider {
    static var previews: some View {
        AmountEditView(label: "Label", amount: .constant(1234.345))
            .preferredColorScheme(.dark)
            .padding(.all)
            .previewLayout(PreviewLayout.sizeThatFits)
            .previewDisplayName("AmountEditView")
    }
}

// MARK: - Library Views

struct AmountViews_Libraries: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        let amount = 1000.0
        LibraryItem(AmountView(label: "Label", amount: amount),
                    title: "Amount View",
                    category: .control,
                    matchingSignature: "amountview")
        LibraryItem(AmountEditView(label: "Label", amount: .constant(1234.3)),
                    title: "Amount Edit View",
                    category: .control,
                    matchingSignature: "amounteditview")
    }
}
