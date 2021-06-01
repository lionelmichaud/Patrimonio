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
    func save(_ encodeData: Data) {
        // impression debug
        #if DEBUG
        print("encoding to file: ", self.url)
        #endif
        if let jsonString = String(data: encodeData, encoding: .utf8) {
            #if DEBUG
            print(jsonString)
            #endif
        } else {
            print("failed to convert encoded object to string")
        }
        do {
            // sauvegader les données
            try self.write(encodeData)
        } catch {
            customLog.log(level: .fault, "Failed to save data to file '\(self.name)'.")
            fatalError("Failed to save data to file '\(self.name)' in bundle.")
        }
    }
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
            print("encoding to file: ", self.url)
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
                customLog.log(level: .fault, "Failed to save data to file '\(self.name)'.")
                fatalError("Failed to save data to file '\(self.name)' in bundle.")
            }
        } else {
            customLog.log(level: .fault, "Failed to encode \(String(describing: T.self)) object to JSON format.")
            fatalError("Failed to encode \(String(describing: T.self)) object to JSON format.")
        }
    }
}

public extension File {
    func loadFromJSON <T: Decodable> (_ type: T.Type,
                                      dateDecodingStrategy: JSONDecoder.DateDecodingStrategy = .deferredToDate,
                                      keyDecodingStrategy : JSONDecoder.KeyDecodingStrategy  = .useDefaultKeys) -> T {
        // MARK: - DEBUG - A supprimer
        #if DEBUG
        print("decoding file: ", self.url)
        #endif
        
        // load data from URL
        guard let data = try? self.read() else {
            customLog.log(level: .fault, "Failed to load file '\(self.name)' from file '\(self.name)'.")
            fatalError("Failed to load file '\(self.name)' from file '\(self.name)'.")
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = dateDecodingStrategy
        decoder.keyDecodingStrategy = keyDecodingStrategy
        
        // decode JSON data
        let failureString = "Failed to decode object of type '\(String(describing: T.self))' from file '\(self.name)'."
        do {
            return try decoder.decode(T.self, from: data)
        } catch DecodingError.keyNotFound(let key, let context) {
            customLog.log(level: .fault,
                          "\(failureString)from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription).")
            fatalError("\(failureString)from bundle due to missing key '\(key.stringValue)' not found – \(context.debugDescription)")
        } catch DecodingError.typeMismatch(_, let context) {
            customLog.log(level: .fault,
                          "\(failureString)from bundle due to type mismatch – \(context.debugDescription)")
            fatalError("\(failureString)from bundle due to type mismatch – \(context.debugDescription)")
        } catch DecodingError.valueNotFound(let type, let context) {
            customLog.log(level: .fault,
                          "\(failureString)from bundle due to missing \(type) value – \(context.debugDescription).")
            fatalError("\(failureString)from bundle due to missing \(type) value – \(context.debugDescription)")
        } catch DecodingError.dataCorrupted(let context) {
            customLog.log(level: .fault,
                          "\(failureString)from bundle because it appears to be invalid JSON \n \(context.codingPath) \n \(context.debugDescription).")
            fatalError("\(failureString)from bundle because it appears to be invalid JSON \n \(context.codingPath) \n \(context.debugDescription)")
        } catch {
            customLog.log(level: .fault,
                          "\(failureString)from bundle: \(error.localizedDescription).")
            fatalError("\(failureString)from bundle: \(error.localizedDescription)")
        }
    }
}
