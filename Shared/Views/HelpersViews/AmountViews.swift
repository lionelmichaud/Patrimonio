//
//  AmountViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI

// MARK: - Saisie d'un montant en €

struct AmountEditView: View {
    let label            : String
    let comment          : String?
    let currency         : Bool
    @Binding var amount  : Double
    @State var text      : String
    var textValueBinding : Binding<String> {
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
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            if comment != nil { Text(comment!).foregroundColor(.secondary) }
            TextField("montant",
                      text: textValueBinding)
                .frame(maxWidth: 88)
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
        .textFieldStyle(RoundedBorderTextFieldStyle())
    }
    
    init(label    : String,
         comment  : String?  = nil,
         amount   : Binding<Double>,
         currency : Bool = true) {
        self.label    = label
        self.comment  = comment
        self.currency = currency
        self._amount  = amount
        _text = State(initialValue: String(amount.wrappedValue).replacingOccurrences(of: ".", with: ","))
        //        print("created: value = \(amount); text = \(text)")
    }
}

// MARK: - Affichage d'un montant en €

/// Affichage d'une valeur numérique Double
/// - Parameter:
///   - label: Libellé à gauche
///   - amount: valeure numérique à afficher à droite
///   - digit: Nombre de digit à afficher
///   - weight: Taille de la police utilisée pour `label` et `amount`
///   - comment: Commentaire à afficher en grisé à gauche de la valeur
struct AmountView: View {
    let label   : String
    let amount  : Double
    let digit   : Int
    let kEuro   : Bool
    let weight  : Font.Weight
    let comment : String?
    
    var body: some View {
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
    
    /// Création de la View
    /// - Parameters:
    ///   - label: Libellé à gauche
    ///   - amount: valeure numérique à afficher à droite
    ///   - digit: Nombre de digit à afficher
    ///   - weight: Taille de la police utilisée pour `label` et `amount`
    ///   - comment: Commentaire à afficher en grisé à gauche de la valeur
    init(label   : String,
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
            AmountView(label: "Label", amount: 1234.3)
                .preferredColorScheme(.dark)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("AmountView")
            AmountEditView(label: "Label", amount: .constant(1234.3))
                .preferredColorScheme(.dark)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding([.bottom, .top])
                .previewDisplayName("AmountEditView")
        }
    }
}

struct AmountEditView_Previews: PreviewProvider {
    static var previews: some View {
        AmountEditView(label: "Label", amount: .constant(1234.3))
            .preferredColorScheme(.dark)
            .previewLayout(PreviewLayout.sizeThatFits)
            .padding([.bottom, .top])
            .previewDisplayName("AmountEditView")
            .previewDevice("iPhone 12")
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
