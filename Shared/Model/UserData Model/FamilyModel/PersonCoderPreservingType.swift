//
//  PersonCoderPreservingType.swift
//  Patrimonio
//
//  Created by Lionel MICHAUD on 19/04/2021.
//

import Foundation
import TypePreservingCodingAdapter // https://github.com/IgorMuzyka/Type-Preserving-Coding-Adapter.git

struct PersonCoderPreservingType {
    let adapter = TypePreservingCodingAdapter()
    let encoder = JSONEncoder()
    let decoder = JSONDecoder()
    
    init() {
        self.encoder.outputFormatting     = .prettyPrinted
        self.encoder.dateEncodingStrategy = .iso8601
        self.encoder.keyEncodingStrategy  = .useDefaultKeys
        
        self.decoder.dateDecodingStrategy = .iso8601
        self.decoder.keyDecodingStrategy  = .useDefaultKeys
        
        // inject it into encoder and decoder
        self.encoder.userInfo[.typePreservingAdapter] = self.adapter
        self.decoder.userInfo[.typePreservingAdapter] = self.adapter
        
        // register your types with adapter
        self.adapter
            .register(type: Person.self)
            .register(alias: "personne", for: Person.self)
            .register(type: Adult.self)
            .register(alias: "adult", for: Adult.self)
            .register(type: Child.self)
            .register(alias: "enfant", for: Child.self)
    }
}

