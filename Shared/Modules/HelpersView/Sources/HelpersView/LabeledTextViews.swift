//
//  LabeledTextViews.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 04/02/2022.
//

import SwiftUI
import AppFoundation

// MARK: - Saisie d'un text "TextEditor"

/// Editer un texte d'une ligne
/// - Parameters:
///   - label: texte à gauche
///   - labelWidth: largeur du label (70 par défaut)
///   - text: texte éditable à droite
public struct LabeledTextEditor : View {
    private let label      : String
    private let labelWidth : Int
    private let validity   : StringValidityRule
    @Binding
    private var text       : String

    public var body: some View {
        HStack {
            Text(label)
                .frame(width: Double(labelWidth), alignment: .leading)
            TextEditor(text: $text)
                .border(Color("borderTextColor"), width: 1)
        }
        .textFieldStyle(.roundedBorder)
        .foregroundColor(validity.isValid(text: text) ? .primary : .red)
    }
    
    /// Editer un texte d'une ligne
    /// - Parameters:
    ///   - label: texte à gauche
    ///   - labelWidth: largeur du label (70 par défaut)
    ///   - text: texte éditable à droite
    public init(label       : String,
                labelWidth  : Int = 70,
                text        : Binding<String>,
                validity    : StringValidityRule = .none) {
        self.label       = label
        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
        self.validity    = validity
        self._text       = text
    }
}

// MARK: - Saisie d'un text "TextField"

/// Editer un texte de plusieurs lignes
/// - Parameters:
///   - label: texte à gauche
///   - labelWidth: largeur du label (70 par défaut)
///   - defaultText: texte par défaut si le `text`initial est vide
///   - text: texte éditable à droite
public struct LabeledTextField : View {
    private let label       : String
    private let labelWidth  : Int
    private let defaultText : String?
    private let validity    : StringValidityRule
    @Binding
    private var text        : String

    public var body: some View {
        HStack {
            Text(label)
                .frame(width: Double(labelWidth), alignment: .leading)
            TextField(defaultText ?? "", text: $text)
        }
        .foregroundColor(validity.isValid(text: text) ? .primary : .red)
    }
    
    /// Editer un texte de plusieurs lignes
    /// - Parameters:
    ///   - label: texte à gauche
    ///   - labelWidth: largeur du label (70 par défaut)
    ///   - defaultText: texte par défaut si le `text`initial est vide
    ///   - text: texte éditable à droite
    public init(label       : String,
                labelWidth  : Int = 70,
                defaultText : String? = nil,
                text        : Binding<String>,
                validity    : StringValidityRule = .none) {
        self.label       = label
        self.labelWidth  = labelWidth > 0 ? labelWidth : 70
        self.defaultText = defaultText
        self.validity    = validity
        self._text       = text
    }
    
}

// MARK: - Affichage d'un text "text"

/// Affiche un `label` au gauche et un `text` droite
public struct LabeledText: View {
    private let label : String
    private let text  : String
    
    public var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(text)
        }
    }
    
    /// Affiche un `label` au gauche et un `text` droite
    public init(label   : String,
                text    : String,
                comment : String?  = nil) {
        self.label   = label
        self.text    = text
    }
}

// MARK: - PreViews

struct LabeledTextViews_Previews: PreviewProvider { 
    static var previews: some View {
        Group {
            LabeledText(label: "Label", text: "Text à afficher", comment: "Comment")
                .padding()
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("LabeledText")
            LabeledTextField(label: "Label", labelWidth: 70, defaultText: "Obligatoire", text: .constant("Text à éditer"))
                .padding()
                .previewLayout(PreviewLayout.sizeThatFits)
                .previewDisplayName("LabeledTextField")
            LabeledTextEditor(label: "Label", labelWidth: 70, text: .constant("Text à éditer"))
                .padding()
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
