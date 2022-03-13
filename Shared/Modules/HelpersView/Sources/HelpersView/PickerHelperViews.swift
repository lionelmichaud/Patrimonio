//
//  PickerHelperViews.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 23/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import AppFoundation

// MARK: - Saisie d'une Année
public struct YearPicker: View {
    private let title     : String
    private let inRange   : ClosedRange<Int>
    @Binding
    private var selection : Int
    @State
    private var rows = [Int]()
    
    public var body: some View {
        Picker(title, selection: $selection) {
            ForEach(rows, id: \.self) { year in
                Text(String(year))
            }
        }
        .onAppear( perform: { self.inRange.forEach {self.rows.append($0)}})
    }

    public init(title     : String,
                inRange   : ClosedRange<Int>,
                selection : Binding<Int>) {
        self.title      = title
        self.inRange    = inRange
        self._selection = selection
    }
}

// MARK: - Saisie d'un Enum
public struct CasePicker<T: PickableEnumP>: View where T.AllCases: RandomAccessCollection {
    @Binding
    private var pickedCase: T
    private let label: String
    
    public var body: some View {
        Picker(selection: $pickedCase, label: Text(label)) {
            ForEach(T.allCases, id: \.self) { enu in
                Text(enu.pickerString)
            }
        }
    }

    public init(pickedCase : Binding<T>,
                label      : String) {
        self.label      = label
        self._pickedCase = pickedCase
    }
}

// MARK: - Saisie d'un Enum avec Valeurs associées
public struct CaseWithAssociatedValuePicker<T: PickableIdentifiableEnumP>: View where T.AllCases: RandomAccessCollection {
    @Binding
    public var caseIndex: Int
    public let label: String
    
    public var body: some View {
        Picker(selection: $caseIndex, label: Text(label)) {
            ForEach(T.allCases) { enu in
                Text(enu.pickerString).tag(enu.id)
            }
        }
    }

    public init(caseIndex : Binding<Int>,
                label     : String) {
        self.label      = label
        self._caseIndex = caseIndex
    }
}

// MARK: - Tests & Previews

struct PickerHelperViews_Previews: PreviewProvider {
    enum TestEnum: Int, PickableEnumP {
        case un, deux, trois
        var pickerString: String {
            switch self {
                case .un:
                    return "Un"
                case .deux:
                    return "Deux"
                case .trois:
                    return "Trois"
            }
        }
    }

    static var previews: some View {
        Group {
            YearPicker(title: "Année", inRange: 2010...2025, selection: .constant(2020))
                .preferredColorScheme(.dark)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding(.all)
                .previewDisplayName("YearPicker")
            CasePicker<TestEnum>(pickedCase: .constant(TestEnum.deux), label: "Enum")
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding(.all)
                .previewDisplayName("CasePicker<TestEnum>")
        }
    }
}

// MARK: - Library Views

// swiftlint:disable type_name
struct PickersView_Library: LibraryContentProvider {
    enum TestEnum: Int, PickableEnumP {
        case un, deux, trois
        var pickerString: String {
            switch self {
                case .un:
                    return "Un"
                case .deux:
                    return "Deux"
                case .trois:
                    return "Trois"
            }
        }
    }

    @LibraryContentBuilder
    var views: [LibraryItem] {
        LibraryItem(YearPicker(title: "Année", inRange: 2010...2025, selection: .constant(2020)),
                    title: "Year Picker",
                    category: .control,
                    matchingSignature: "yearpicker")
        LibraryItem(CasePicker(pickedCase: .constant(TestEnum.deux), label: "Enum"),
                    title: "Enum Picker",
                    category: .control,
                    matchingSignature: "enumpicker")
    }
}
