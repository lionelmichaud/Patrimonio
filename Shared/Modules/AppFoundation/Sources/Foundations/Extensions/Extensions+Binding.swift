//
//  Extensions+Binding.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 11/11/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI
import Combine

public extension Binding {
    /// Créer un Binding sur un Optional
    ///
    /// Usage:
    ///
    ///     init(label    : String,
    ///          boundary : Binding<DateBoundaryViewModel?>) {
    ///         self.label  = label
    ///         _boundaryVM = boundary ?? DateBoundaryViewModel(from: DateBoundary.empty)
    ///     }
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

/// PropertyWrapper: `@Transac` binding for SwiftUI to make changes to data supporting commit/rollback
///
/// Usage:
///
///     struct UserEditView: View {
///     @Transac var value: User
///
///     var body: some View {
///         VStack {
///             TextField("First Name", text: $value.firstName)
///             TextField("Last Name", text: $value.lastName)
///             Divider()
///             Button("Commit", action: $value.commit).disabled(!$value.hasChanges)
///             Button("Rollback", action: $value.rollback).disabled(!$value.hasChanges)
///         }
///      }
///    }
///
/// - Note: [Reference](https://github.com/nsscreencast/397-swiftui-tip-calculator/blob/master/TipCalculator/TipCalculator/ContentView.swift)
///
@propertyWrapper
@dynamicMemberLookup
public struct Transac<Value>: DynamicProperty {
    @State private var derived: Value
    @Binding private var source: Value

    fileprivate init(source: Binding<Value>) {
        self._source = source
        self._derived = State(wrappedValue: source.wrappedValue)
    }

    public init(source: Value) {
        var source = source
        let binding = Binding(get: { source }, set: { source = $0 })
        self.init(source: binding)
    }

    public var wrappedValue: Value {
        get { derived }
        nonmutating set { derived = newValue }
    }

    public var projectedValue: Transac<Value> { self }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Value, T>) -> Binding<T> {
        return $derived[dynamicMember: keyPath]
    }

    public var binding: Binding<Value> { $derived }

    public func commit() {
        source = derived
    }
    public func rollback() {
        derived = source
    }
}

extension Transac where Value: Equatable {
    public var hasChanges: Bool { source != derived }
}

extension Transac where Value: Equatable, Value: ValidableP {
    public var hasValidChanges: Bool { source != derived && derived.isValid }
}

extension Binding {
    public func transaction() -> Transac<Value> { .init(source: self) }
}
