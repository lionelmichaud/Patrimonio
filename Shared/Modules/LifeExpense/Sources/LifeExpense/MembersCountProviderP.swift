//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 09/08/2021.
//

import Foundation

// MARK: - DI: Protocol de service de fourniture de dénombrement dans la famille

public protocol MembersCountProviderP {
    var nbOfBornChildren: Int { get }
    var nbOfAdults: Int { get }
    func nbOfAdultAlive(atEndOf year: Int) -> Int
    func nbOfChildrenAlive(atEndOf year: Int) -> Int
    func nbOfFiscalChildren(during year: Int) -> Int
}
