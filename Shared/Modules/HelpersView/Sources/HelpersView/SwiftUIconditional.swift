//
//  SwiftUIconditional.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

public extension NavigationLink {
    func isiOSDetailLink(_ detail: Bool) -> some View {
        #if os(iOS) || os(tvOS)
        return self.isDetailLink(detail)
        #else
        return self
        #endif
    }
}

// MARK: - View Extensions

public extension View {
    /// Sets the style for lists within this view.
    @ViewBuilder
    func defaultSideBarListStyle() -> some View {
        #if os(iOS) || os(tvOS)
        if #available(iOS 14.0, *) {
            self
                .listStyle(.insetGrouped)
        } else {
            self
                .listStyle(.grouped)
        }
        #else
        self
            .listStyle(.sidebar)
        #endif
    }
    
    /// Conditional View modifier InsetGroupedList
    ///
    /// Usage:
    ///
    ///     var body: some view {
    ///         myView
    ///             .insetGroupedListStyle()
    ///     }
    ///
    /// - Note: [reference](https://www.fivestars.blog/articles/conditional-modifiers/)
    @ViewBuilder
    func insetGroupedListStyle() -> some View {
        #if os(iOS) || os(tvOS)
        if #available(iOS 14.0, *) {
            self
                .listStyle(.insetGrouped)
        } else {
            self
                .listStyle(.grouped)
                .environment(\.horizontalSizeClass, .regular)
        }
        #else
        self
            .listStyle(.automatic)
        #endif
    }
    
    @ViewBuilder
    func numbersAndPunctuationKeyboardType() -> some View {
        #if os(iOS) || os(tvOS)
        self.keyboardType(.numbersAndPunctuation)
        #else
        return self
        #endif
    }
    
    @ViewBuilder
    func decimalPadKeyboardType() -> some View {
        #if os(iOS) || os(tvOS)
        self.keyboardType(.decimalPad)
        #else
        self
        #endif
    }
    
    @ViewBuilder
    func navigationBarTitleDisplayModeInline() -> some View {
        #if os(iOS) || os(tvOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
    
    /// Conditional View modifier
    ///
    /// Usage:
    ///
    ///     var body: some view {
    ///         myView
    ///             .if(X) { $0.padding(8) }
    ///             .if(Y) { $0.background(Color.blue) }
    ///     }
    ///
    /// - Note: [reference](https://www.fivestars.blog/articles/conditional-modifiers/)
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    /// Conditional View modifier
    ///
    /// Usage:
    ///
    ///     var body: some view {
    ///         myView
    ///             .if(X) { $0.padding(8) } else: { $0.background(Color.blue) }
    ///     }
    ///
    /// - Note: [reference](https://www.fivestars.blog/articles/conditional-modifiers/)
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if ifTransform: (Self) -> TrueContent,
        else elseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            ifTransform(self)
        } else {
            elseTransform(self)
        }
    }
    
    /// Conditional View modifier
    ///
    /// Usage:
    ///
    ///     var body: some view {
    ///         myView
    ///             .ifLet(optionalColor) { $0.foregroundColor($1) }
    ///     }
    ///
    /// - Note: [reference](https://www.fivestars.blog/articles/conditional-modifiers/)
    @ViewBuilder
    func ifLet<V, Transform: View>(
        _ value: V?,
        transform: (Self, V) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
    
    /// Conditional View modifier
    ///
    /// Usage:
    ///
    ///     var body: some view {
    ///         myView
    ///             .ifmacOS { $0.padding(8) }
    ///     }
    ///
    /// - Note: [reference](https://www.fivestars.blog/articles/conditional-modifiers/)
    @ViewBuilder
    func ifmacOS<Transform: View>(transform: (Self) -> Transform) -> some View {
        #if os(macOS)
        transform(self)
        #else
        self
        #endif
    }
    
    /// Conditional View modifier
    ///
    /// Usage:
    ///
    ///     var body: some view {
    ///         myView
    ///             .ifiOS { $0.padding(8) }
    ///     }
    ///
    /// - Note: [reference](https://www.fivestars.blog/articles/conditional-modifiers/)
    @ViewBuilder
    func ifiOS<Transform: View>(transform: (Self) -> Transform) -> some View {
        #if os(iOS) || os(tvOS)
        transform(self)
        #else
        self
        #endif
    }
}
