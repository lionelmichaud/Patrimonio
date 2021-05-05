//
//  Extensions+Optional.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 16/06/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

/// https://stackoverflow.com/questions/57021722/swiftui-optional-textfield
/// Usage:
///     struct SOTestView : View {
///         @State var test: String? = "Test"
///
///         var body: some View {
///             TextField($test.bound)
///         }
///     }
public extension Optional where Wrapped == String {
    private var _bound: String? {
        get {
            return self
        }
        set {
            self = newValue
        }
    }
    var bound: String {
        get {
            return _bound ?? ""
        }
        set {
            _bound = newValue.isEmpty ? nil : newValue
        }
    }
}
