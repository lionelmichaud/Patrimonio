//
//  Extension+File-Image.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 27/05/2021.
//

import Foundation
import UIKit
import Files

extension File {
    
    enum ImageConvertionError: String, Error {
        case faileToSerializeToPNG = "Could not serialize UIImage to PNG"
        case faileToSerializeToJPG = "Could not serialize UIImage to JPEG"
        case faileToSerializeToData = "Could not serialize UIImage to Data"
    }
    /// Write a new `image` into this file, replacing its current contents.
    /// - parameter image: The binary image data to write.
    /// - throws: `WriteError` in case the operation couldn't be completed.
    func write(_ image: UIImage) throws {
        do {
            var imageData: Data
            if path.suffix(4).lowercased() == ".png" {
                let pngData: Data?
                #if swift(>=4.2)
                pngData = image.pngData()
                #else
                pngData = UIImagePNGRepresentation(value)
                #endif
                if let data = pngData {
                    imageData = data
                } else {
                    throw WriteError(path: path,
                                     reason: .writeFailed(ImageConvertionError.faileToSerializeToPNG))
                }
            } else if path.suffix(4).lowercased() == ".jpg" || path.suffix(5).lowercased() == ".jpeg" {
                let jpegData: Data?
                #if swift(>=4.2)
                jpegData = image.jpegData(compressionQuality: 1)
                #else
                jpegData = UIImageJPEGRepresentation(value, 1)
                #endif
                if let data = jpegData {
                    imageData = data
                } else {
                    throw WriteError(path: path,
                                     reason: .writeFailed(ImageConvertionError.faileToSerializeToJPG))
                }
            } else {
                var data: Data?
                #if swift(>=4.2)
                if let pngData = image.pngData() {
                    data = pngData
                } else if let jpegData = image.jpegData(compressionQuality: 1) {
                    data = jpegData
                }
                #else
                if let pngData = UIImagePNGRepresentation(value) {
                    data = pngData
                } else if let jpegData = UIImageJPEGRepresentation(value, 1) {
                    data = jpegData
                }
                #endif
                if let data = data {
                    imageData = data
                } else {
                    throw WriteError(path: path,
                                     reason: .writeFailed(ImageConvertionError.faileToSerializeToData))
                }
            }
            try self.write(imageData)
        } catch {
            throw WriteError(path: path, reason: .writeFailed(error))
        }
    }
}
