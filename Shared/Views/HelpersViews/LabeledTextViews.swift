//
//  LabeledTextViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI

// MARK: - Saisie d'un text "TextEditor"

struct LabeledTextEditor : View {
    let label         : String
    let labelWidth    : Int
    @Binding var text : String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: CGFloat(labelWidth), alignment: .leading)
            TextEditor(text: $text)
                .border(Color("borderTextColor"), width: 1)
        }
    }
    
    init(label       : String,
         labelWidth  : Int = 70,
         text        : Binding<String>) {
        self.label       = label
        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
        self._text       = text
    }
}

// MARK: - Saisie d'un text "TextField"

/// Affiche un `label` au gauche et un `text` éditable à droite
///   - label: texte à gauche
///   - labelWidth: largeur du label (70 par défaut)
///   - defaultText: texte par défaut si le `text`initial est vide
///   - text: texte éditable à droite
struct LabeledTextField : View {
    let label         : String
    let labelWidth    : Int
    let defaultText   : String?
    @Binding var text : String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: CGFloat(labelWidth), alignment: .leading)
            TextField(defaultText ?? "", text: $text)
        }
    }
    
    /// Affiche un `label` au gauche et un `text` à droite
    /// - Parameters:
    ///   - label: texte à gauche
    ///   - labelWidth: largeur du label (70 par défaut)
    ///   - defaultText: texte par défaut si le `text`initial est vide
    ///   - text: texte éditable à droite
    init(label       : String,
         labelWidth  : Int = 70,
         defaultText : String? = nil,
         text        : Binding<String>) {
        self.label       = label
        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
        self.defaultText = defaultText
        self._text       = text
    }
    
}

// MARK: - Affichage d'un text "text"

struct LabeledText: View {
    let label : String
    let text  : String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(text)
        }
    }
    
    init(label: String, text : String, comment: String? = nil) {
        self.label   = label
        self.text    = text
    }
}

// MARK: - PreViews

struct LabeledTextViews_Previews: View { // swiftlint:disable:this type_name
    var body: some View {
        Group {
            LabeledText(label: "Label", text: "Text", comment: "Comment")
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("LabeledText")
            LabeledTextField(label: "Label", labelWidth: 70, defaultText: "Obligatoire", text: .constant("text"))
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("LabeledTextField")
            LabeledTextEditor(label: "Label", labelWidth: 70, text: .constant("text"))
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("LabeledTextEditor")
        }
    }
}

// MARK: - Library Views

struct LabeledTextViews_Library: LibraryContentProvider { // swiftlint:disable:this type_name
    @LibraryContentBuilder var views: [LibraryItem] {
        LibraryItem(LabeledText(label: "Label", text: "Text", comment: "Comment"),
                    title: "Labeled Text",
                    category: .control,
                    matchingSignature: "labeltext")
        LibraryItem(LabeledTextField(label: "Label", labelWidth: 70, defaultText: "Obligatoire", text: .constant("text")),
                    title: "Labeled TextField",
                    category: .control,
                    matchingSignature: "labeltextfield")
        LibraryItem(LabeledTextEditor(label: "Label", labelWidth: 70, text: .constant("text")),
                    title: "Labeled TextEditor",
                    category: .control,
                    matchingSignature: "labeltexteditor")
    }
}
