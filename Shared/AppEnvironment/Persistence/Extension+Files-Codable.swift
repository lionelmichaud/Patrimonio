//
//  Extension+File.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 25/05/2021.
//

import Foundation
import os
import Files

private let customLog = Logger(subsystem: "me.michaud.lionel.Patrimonio", category: "Extensions.Files-Codable")

public extension File {
    func saveAsJSON <T: Encodable> (_ object: T,
                                    dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate,
                                    keyEncodingStrategy : JSONEncoder.KeyEncodingStrategy  = .useDefaultKeys) {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = dateEncodingStrategy
        encoder.keyEncodingStrategy = keyEncodingStrategy
        
        if let encoded = try? encoder.encode(object) {
            // impression debug
            #if DEBUG
            print("encoding to file: ", self.name)
            #endif
            if let jsonString = String(data: encoded, encoding: .utf8) {
                #if DEBUG
                print(jsonString)
                #endif
            } else {
                print("failed to convert \(String(describing: T.self)) object to string")
            }
            do {
                // sauvegader les données
                try self.write(encoded)
            } catch {
                customLog.log(level: .fault, "Failed to save data to file '\(self.name)' in bundle.")
                fatalError("Failed to save data to file '\(self.name)' in bundle.")
            }
        } else {
            customLog.log(level: .fault, "Failed to encode \(String(describing: T.self)) object to JSON format.")
            fatalError("Failed to encode \(String(describing: T.self)) object to JSON format.")
        }
    }
}
