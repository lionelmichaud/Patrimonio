//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 04/12/2021.
//

import Foundation

// MARK: - Bucket

struct Bucket: Codable {
    
    // MARK: - Properties
    
    let Xmin     : Double // limite inférieure de la case
    let Xmed     : Double // milieu de la case
    var Xmax     : Double // limite supérieure de la case
    var sampleNb : Int = 0 // nombre d'échantillonsdans la case
    
    // MARK: - Initializer
    
    /// Créer un Bucket
    /// - Parameters:
    ///   - Xmin: borne inférieure
    ///   - Xmax: borne supérieure
    ///   - step: utilisé pour calculer le centre de la case si `Xmin` ou `Xmax` = -/+ `Double.infinity`
    ///
    /// - Note:
    ///   - Si `Xmax` = +`Double.infinity` alors:
    ///     - Si `step` ≠ `nil` alors `Xmed` = `Xmin` + `step`
    ///     - sinon `Xmed` = `Xmin`
    ///
    init(Xmin              : Double,
         Xmax              : Double,
         borderBucketWidth : Double?  = nil) {
        precondition(Xmin < Xmax, "Bucket.init: Xmin >= Xmax")
        precondition(Xmin != -Double.infinity || Xmax != Double.infinity, "Histogram.init: les 2 bornes ne peuvent pas être infinies")
        self.Xmin = Xmin
        if Xmin == -Double.infinity {
            self.Xmed = borderBucketWidth != nil ? Xmax - borderBucketWidth! : Xmax
        } else if Xmax == Double.infinity {
            self.Xmed = borderBucketWidth != nil ? Xmin + borderBucketWidth! : Xmin
        } else {
            self.Xmed = (Xmax + Xmin) / 2
        }
        self.Xmax = Xmax
    }
    
    // MARK: - Methods
    
    /// Incrémente le nb d'échantillons de la case
    mutating func record() {
        // incrémente le nombre d'échantillons dans la case
        sampleNb += 1
    }
    /// Vide la case
    mutating func empty() {
        sampleNb = 0
    }
}

typealias BucketsArray = [Bucket]
extension BucketsArray {
    /// Ajoute un échantillon à la bonne case
    ///
    /// Plus grande case telle que (case.Xmin <= data)
    ///
    /// - Parameter data: échantillon
    mutating func record(_ data: Double) {
        // ranger l'échantillon dans une case
        if let idx = self.lastIndex(where: { $0.Xmin <= data }) {
            // incrémente le nombre d'échantillons dans la case
            self[idx].record()
        }
    }
    
    /// Ajoute un tableau d'échantillons à la bonne case
    /// - Parameter sequence: tableau d'échantillons
    mutating func record(_ sequence: [Double]) {
        // ranger l'échantillon dans une case
        for data in sequence {
            record(data)
        }
    }
    
    /// Crée une copie avec toutes les cases vides
    mutating func emptyCopy() -> BucketsArray {
        self.map {
            var newBucket = $0
            newBucket.empty()
            return newBucket
        }
    }
}
