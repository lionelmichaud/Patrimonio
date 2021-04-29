//
//  Extensions+Bool.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 19/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

public extension Bool {
    var frenchString: String {
        self ? "OUI" : "NON"
    }

    static var iOS13: Bool {
        guard #available(iOS 14, *) else {
            // It's iOS 13 so return true.
            return true
        }
        // It's iOS 14 so return false.
        return false
    }
}
