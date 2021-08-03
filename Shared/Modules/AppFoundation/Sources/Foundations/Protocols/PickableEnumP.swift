//
//  PickableEnum.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 15/01/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation

// MARK: - Protocol PickableEnum pour Picker d'un Enum

public protocol PickableEnumP: CaseIterable, Hashable, CustomStringConvertible {
    var pickerString  : String { get }
    var displayString : String { get }
    var description   : String { get }
}

// implémntation par défaut
public extension PickableEnumP {
    // default implementation
    var displayString : String { pickerString }
    var description   : String { displayString }
}

// MARK: - Protocol PickableEnum & Identifiable pour Picker d'un Enum

public typealias PickableIdentifiableEnumP = PickableEnumP & Identifiable
