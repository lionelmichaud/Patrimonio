//
//  SwiftUIconditional.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/07/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

public extension View {
    
    /// Sets the style for lists within this view.
    func defaultSideBarListStyle() -> some View {
        #if os(iOS) || os(tvOS)
        if #available(iOS 14.0, *) {
            return AnyView(self.listStyle(InsetGroupedListStyle()))
        } else {
            return AnyView(self.listStyle(GroupedListStyle()))
        }
        #else
        return AnyView(self.listStyle(SidebarListStyle()))
        #endif
    }
    
    func numbersAndPunctuationKeyboardType() -> some View {
        #if os(iOS) || os(tvOS)
        return AnyView(self.keyboardType(.numbersAndPunctuation))
        #else
        return self
        #endif
    }
    
    func decimalPadKeyboardType() -> some View {
        #if os(iOS) || os(tvOS)
        return AnyView(self.keyboardType(.decimalPad))
        #else
        return self
        #endif
    }

}
