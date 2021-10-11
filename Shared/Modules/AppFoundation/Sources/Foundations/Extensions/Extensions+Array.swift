//
//  Extensions+Array.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 20/04/2020.
//  Copyright © 2020 Lionel MICHAUD. All rights reserved.
//

import Foundation

public extension Collection where Element: AdditiveArithmetic {
    /// Somme de tous les éléméents d'un Array
    ///
    /// Usage:
    ///
    ///     let doubles = [1.5, 2.7, 3.0]
    ///     doubles.sum()    // 7.2
    ///
    /// - Returns: somme de tous les éléméents du tableau
    ///
    ///  - Note: [Reference](https://stackoverflow.com/questions/24795130/finding-sum-of-elements-in-swift-array)
    func sum () -> Element {
        return reduce(.zero, +)
    }
}

public extension Array where Element: Comparable {
    /// Check if two arrays contain the same elements regardless of the order in which those elements appear
    /// - Warning: les élements des tableaux doivent être `Comparable`
    func containsSameElements(as other: [Element]) -> Bool {
        return self.count == other.count && self.sorted() == other.sorted()
    }
}

public extension Array where Element: Hashable {
    /// Check if two arrays contain the same elements regardless of the order in which those elements appear
    /// - Warning: les élements des tableaux doivent être `Comparable`
    func containsSameElements(as other: [Element]) -> Bool {
        let set1 = Set(self)
        let set2 = Set(other)
        
        //if you compare big sets it is recommended to compare the count of items in the sets beforehand
        return (set1.count == set2.count && set1 == set2)
    }
}

public extension Array where Element: SignedNumeric {
    /// Change le signe de tous les éléments du tableau
    static prefix func - (array: [Element]) -> [Element] {
        var newArray = [Element]()
        for idx in array.indices {
            newArray.append(-array[idx])
        }
        return newArray
    }
}

public extension Array {
    /// If you have an array of elements and you want to split them into chunks of a `size` you specify
    ///
    /// Usage:
    ///
    ///     let numbers = Array(1...100)
    ///     let result = numbers.chunked(into: 5) // Hello, Markdown!
    ///
    /// -     ///  - Note: [Reference](https://www.hackingwithswift.com/example-code/language/how-to-split-an-array-into-chunks)
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

public extension Array {
    /// Retrourne true si les éléments du tableau sont ordonnés selon la relation d'ordre `isOrderedBefore`
    /// - Parameter isOrderedBefore: relation d'ordre entre éléments du tableau à utiliser
    /// - Returns: true si les éléments du tableau sont ordonnés selon la relation d'ordre `isOrderedBefore`
    func isSorted(_ isOrderedBefore: (Element, Element) -> Bool) -> Bool {
        for i in 1..<self.count {
            if !isOrderedBefore(self[i-1], self[i]) {
                return false
            }
        }
        return true
    }
}

public extension Array {
    /// Usage:
    ///
    ///     let foundItem = articles.first(\.price, <=, 10.0)
    ///
    func first<T: Comparable>(_ keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> Element? {
        return first(where: { f($0[keyPath: keyPath], value) })
    }
    
    /// Usage:
    ///
    ///     let foundItem = articles.last(\.price, <=, 10.0)
    ///
    func last<T: Comparable>(where keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> Element? {
        return last(where: { f($0[keyPath: keyPath], value) })
    }
    
    /// Usage:
    ///
    ///     let nameOfFoundItem = articles.last(\.name, where: \.price, <=, 10.0)
    ///
    func last<T: Comparable, U>(_ keyPath1: KeyPath<Element, U>, where keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> U? {
        if let lastFound = last(where: { f($0[keyPath: keyPath], value) }) {
            return lastFound[keyPath: keyPath1]
        } else {
            return nil
        }
    }

    /// Usage:
    ///
    ///     let nameOfFoundItem = articles.first(\.name, where: \.price, <=, 10.0)
    ///
    func first<T: Comparable, U>(_ keyPath1: KeyPath<Element, U>, where keyPath: KeyPath<Element, T>, _ f: (T, T) -> Bool, _ value: T) -> U? {
        if let firstFound = last(where: { f($0[keyPath: keyPath], value) }) {
            return firstFound[keyPath: keyPath1]
        } else {
            return nil
        }
    }
}
