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
        let indent          : CGFloat
        let labelFontSize   : CGFloat
        let valueFontSize   : CGFloat
        let opacity         : Double
    }
    
    static let rowsBaseColor = Color("listRowBaseColor")
    static var shared: [ListRowTheme] = [
        // 0
        ListRowTheme(indent          : 0,
                     labelFontSize   : 17,
                     valueFontSize   : 17,
                     opacity         : 1.0),
        // 1
        ListRowTheme(indent          : 0,
                     labelFontSize   : 16,
                     valueFontSize   : 16,
                     opacity         : 0.5),
        // 2
        ListRowTheme(indent          : 0,
                     labelFontSize   : 15,
                     valueFontSize   : 15,
                     opacity         : 0.25),
        // 3
        ListRowTheme(indent          : 0,
                     labelFontSize   : 14,
                     valueFontSize   : 14,
                     opacity         : 0.0)
    ]
    static subscript(idx: Int) -> ListRowTheme {
        ListTheme.shared[idx]
    }
}
