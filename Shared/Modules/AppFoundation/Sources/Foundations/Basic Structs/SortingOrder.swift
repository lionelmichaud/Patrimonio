//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 17/04/2021.
//

import Foundation

// MARK: - Ordre de tri

public enum SortingOrder {
    case ascending
    case descending
    
    public var imageSystemName: String {
        switch self {
            case .ascending:
                return "arrow.up.circle"
            case .descending:
                return "arrow.down.circle"
        }
    }
    public mutating func toggle() {
        switch self {
            case .ascending:
                self = .descending
            case .descending:
                self = .ascending
        }
    }
}
