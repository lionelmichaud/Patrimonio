//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 09/08/2021.
//

import Foundation

public class DateBoundaryBuilder {
    private var boundary: DateBoundary = DateBoundary()
    
    public init() { }
    
    public func fixedYear(_ date: Int) -> DateBoundaryBuilder {
        boundary.fixedYear = date
        boundary.event = nil
        return self
    }
    
    public func on(event         : LifeEvent,
                   of personName : String) -> DateBoundaryBuilder {
        boundary.event = event
        boundary.name  = personName
        boundary.group = nil
        boundary.order = nil
        return self
    }
    
    public func on(event        : LifeEvent,
                   of group     : GroupOfPersons,
                   taking order : SoonestLatest) -> DateBoundaryBuilder {
        boundary.event = event
        boundary.name  = nil
        boundary.group = group
        boundary.order = order
        return self
    }
    
    public func build() -> DateBoundary {
        boundary
    }
    
}
