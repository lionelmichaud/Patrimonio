//
//  ItemArrayGeneric.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 22/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

// MARK: - Table d'Item Generic Valuable and Nameable

public struct ArrayOfNameableValuable<E>: Codable, Versionable where
    E: Codable,
    E: Identifiable,
    E: CustomStringConvertible,
    E: NameableValuable {

    // MARK: - Properties

    public var items          = [E]()
    var fileNamePrefix : String?
    public var version        : Version
    public var currentValue   : Double {
        items.sumOfValues(atEndOf: Date.now.year)
    } // computed

    // MARK: - Subscript

    public subscript(idx: Int) -> E {
        get {
            return  items[idx]
        }
        set(newValue) {
            items[idx] = newValue
        }
    }

    // MARK: - Initializers
    
    public init(fileNamePrefix: String = "") {
        self = Bundle.main.loadFromJSON(ArrayOfNameableValuable.self,
                                        from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                        dateDecodingStrategy : .iso8601,
                                        keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix
    }
    
    public init(for aClass     : AnyClass,
                fileNamePrefix : String = "") {
        let bundle = Bundle(for: aClass)
        self = bundle.loadFromJSON(ArrayOfNameableValuable.self,
                                   from                 : fileNamePrefix + String(describing: E.self) + ".json",
                                   dateDecodingStrategy : .iso8601,
                                   keyDecodingStrategy  : .useDefaultKeys)
        self.fileNamePrefix = fileNamePrefix
    }
    
    // MARK: - Methods
    
    func storeItemsToFile(fileNamePrefix: String = "") {
        // encode to JSON file
        Bundle.main.saveAsJSON(self,
                               to                   : fileNamePrefix + self.fileNamePrefix! + String(describing: E.self) + ".json",
                               dateEncodingStrategy : .iso8601,
                               keyEncodingStrategy  : .useDefaultKeys)
    }
    
    func storeItemsToFile(for aClass     : AnyClass,
                          fileNamePrefix : String = "") {
        let bundle = Bundle(for: aClass)
        // encode to JSON file
        bundle.saveAsJSON(self,
                          to                   : fileNamePrefix + self.fileNamePrefix! + String(describing: E.self) + ".json",
                          dateEncodingStrategy : .iso8601,
                          keyEncodingStrategy  : .useDefaultKeys)
    }
    
    public mutating func move(from indexes   : IndexSet,
                              to destination : Int,
                              fileNamePrefix : String = "") {
        items.move(fromOffsets: indexes, toOffset: destination)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    public mutating func delete(at offsets     : IndexSet,
                                fileNamePrefix : String = "") {
        items.remove(atOffsets: offsets)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    public mutating func add(_ item         : E,
                             fileNamePrefix : String = "") {
        items.append(item)
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    public mutating func update(with item      : E,
                                at index       : Int,
                                fileNamePrefix : String = "") {
        items[index] = item
        self.storeItemsToFile(fileNamePrefix: fileNamePrefix)
    }
    
    public func value(atEndOf: Int) -> Double {
        items.sumOfValues(atEndOf: atEndOf)
    }
    
    public func namedValueTable(atEndOf: Int) -> NamedValueArray {
        var table = NamedValueArray()
        for item in items {
            table.append((name: item.name, value: item.value(atEndOf: atEndOf)))
        }
        return table
    }
}

extension ArrayOfNameableValuable: CustomStringConvertible {
    public var description: String {
        items.reduce("") { r, item in
            r + item.description + "\n\n"
        }
    }
}
