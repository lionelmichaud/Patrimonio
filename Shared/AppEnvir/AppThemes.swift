//
//  Graphs.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 10/05/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import SwiftUI

struct ListTheme {
    struct ListRowTheme {
        let indent          : Double
        let labelFontSize   : Double
        let valueFontSize   : Double
        let opacity         : Double
    }
    
    static let rowsBaseColor = Color("listRowBaseColor")
    static var shared: [ListRowTheme] = [
        // 0
        ListRowTheme(indent          : 0,
                     labelFontSize   : 20,
                     valueFontSize   : 20,
                     opacity         : 1.0),
        // 1
        ListRowTheme(indent          : 20,
                     labelFontSize   : 18,
                     valueFontSize   : 18,
                     opacity         : 0.75),
        // 2
        ListRowTheme(indent          : 25,
                     labelFontSize   : 16,
                     valueFontSize   : 16,
                     opacity         : 0.5),
        // 3
        ListRowTheme(indent          : 30,
                     labelFontSize   : 14,
                     valueFontSize   : 14,
                     opacity         : 0.25)
    ]
    static subscript(idx: Int) -> ListRowTheme {
        ListTheme.shared[idx]
    }
}
