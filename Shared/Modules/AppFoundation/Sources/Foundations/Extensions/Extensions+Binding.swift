//
//  Extensions+Binding.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import SwiftUI

public extension Binding {
    static func ?? (lhs: Binding<Value?>, rhs: Value) -> Binding<Value> {
        return Binding(get: { lhs.wrappedValue ?? rhs },
                       set: { lhs.wrappedValue = $0 })
    }
}

public extension Binding {
    /// Observer
    ///
    /// Usage:
    ///
    ///     struct ContentView: View {
    ///         @State private var name = ""
    ///
    ///         var body: some View {
    ///             TextField("Enter your name:", text: $name.onChange(nameChanged))
    ///                 .textFieldStyle(.roundedBorder)
    ///         }
    ///
    ///         func nameChanged(to value: String) {
    ///             print("Name changed to \(name)!")
    ///         }
    ///     }
    func onChange(_ handler: @escaping (Value) -> Void) -> Binding<Value> {
        Binding(
            get: { self.wrappedValue },
            set: { newValue in
                self.wrappedValue = newValue
                handler(newValue)
            }
        )
    }
}
