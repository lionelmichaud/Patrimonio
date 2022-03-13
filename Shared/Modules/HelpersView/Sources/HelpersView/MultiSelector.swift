//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 13/03/2022.
//

import SwiftUI

public struct MultiSelector<LabelView: View, Selectable: Identifiable & Hashable>: View {
    private let label          : LabelView
    private let options        : [Selectable]
    private let optionToString : (Selectable) -> String
    private var selected: Binding<Set<Selectable>>
    
    private var formattedSelectedListString: String {
        ListFormatter.localizedString(byJoining: selected.wrappedValue.map { optionToString($0) })
    }
    
    public var body: some View {
        NavigationLink(destination: multiSelectionView()) {
            HStack {
                label
                Spacer()
                Text(formattedSelectedListString)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
    
    public init(label          : LabelView,
                options        : [Selectable],
                optionToString : @escaping (Selectable) -> String,
                selected       : Binding<Set<Selectable>>) {
        self.label          = label
        self.options        = options
        self.optionToString = optionToString
        self.selected       = selected
    }

    private func multiSelectionView() -> some View {
        MultiSelectionView(
            options: options,
            optionToString: optionToString,
            selected: selected
        )
    }
}

struct MultiSelectionView<Selectable: Identifiable & Hashable>: View {
    let options        : [Selectable]
    let optionToString : (Selectable) -> String
    
    @Binding var selected: Set<Selectable>
    
    var body: some View {
        List {
            ForEach(options) { selectable in
                Button(action: { toggleSelection(selectable: selectable) },
                       label: {
                        HStack {
                            Text(optionToString(selectable)).foregroundColor(.black)
                            Spacer()
                            if selected.contains { $0.id == selectable.id } {
                                Image(systemName: "checkmark").foregroundColor(.accentColor)
                            }
                        }
                       }).tag(selectable.id)
            }
        }.listStyle(GroupedListStyle())
    }
    
    private func toggleSelection(selectable: Selectable) {
        if let existingIndex = selected.firstIndex(where: { $0.id == selectable.id }) {
            selected.remove(at: existingIndex)
        } else {
            selected.insert(selectable)
        }
    }
}

struct MultiSelectionView_Previews: PreviewProvider {
    struct IdentifiableString: Identifiable, Hashable {
        let string : String
        var id     : String { string }
    }
    
    @State static var selected: Set<IdentifiableString> = Set(["A", "C"].map { IdentifiableString(string: $0) })
    
    static var previews: some View {
        NavigationView {
            MultiSelectionView(
                options: ["A", "B", "C", "D"].map { IdentifiableString(string: $0) },
                optionToString: { $0.string },
                selected: $selected
            )
        }
    }
}

struct MultiSelector_Previews: PreviewProvider {
    struct IdentifiableString: Identifiable, Hashable {
        let string: String
        var id: String { string }
    }
    
    @State static var selected: Set<IdentifiableString> = Set(["A", "C"].map { IdentifiableString(string: $0) })
    
    static var previews: some View {
        NavigationView {
            EmptyView()
            Form {
                MultiSelector<Text, IdentifiableString>(
                    label: Text("Multiselect"),
                    options: ["A", "B", "C", "D"].map { IdentifiableString(string: $0) },
                    optionToString: { $0.string },
                    selected: $selected
                )
            }.navigationTitle("Title")
        }
    }
}
