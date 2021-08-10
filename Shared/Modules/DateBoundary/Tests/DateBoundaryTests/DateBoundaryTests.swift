//
//  DateBoundaryTests.swift
//  PatrimoineTests
//
//  Created by Lionel MICHAUD on 20/02/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import XCTest
@testable import DateBoundary

class DateBoundaryTests: XCTestCase {
    
    struct Provider: PersonEventYearProviderP {
        func yearOf(lifeEvent : LifeEvent,
                    for name  : String) -> Int? {
            if name == "M. Lionel MICHAUD" {
                switch lifeEvent {
                    case .deces:
                        return 2080
                    case .dependence:
                        return 2070
                    default:
                        return 2047
                }
            } else {
                return nil
            }
        }
        
        func yearOf(lifeEvent : LifeEvent,
                    for group : GroupOfPersons,
                    order     : SoonestLatest) -> Int? {
            switch group {
                case .allAdults:
                    switch lifeEvent {
                        case .deces, .dependence:
                            return yearOf(lifeEvent: lifeEvent, for: "M. Lionel MICHAUD")
                        default:
                            return 2047
                    }
                    
                default: return nil
            }
        }
    }
    
    static let provider = Provider()
    
    // MARK: Helpers
    
    override class func setUp() {
        super.setUp()
        DateBoundary.setPersonEventYearProvider(provider)
    }
    
    // MARK: Tests
    
    func test_CuctomString() throws {
        print("\nTest de DateBoundary.description")
        
        var boundary = DateBoundary(event: LifeEvent.deces,
                                    name: "M. Lionel MICHAUD")
        print(boundary)
        
        boundary = DateBoundary(event: LifeEvent.dependence,
                                group: GroupOfPersons.allAdults,
                                order: SoonestLatest.soonest)
        print(boundary)
        
        boundary = DateBoundary(event: LifeEvent.deces,
                                group: GroupOfPersons.allChildrens,
                                order: SoonestLatest.latest)
        print(boundary)
        
        boundary = DateBoundary(fixedYear: 2020)
        print(boundary)
    }
    
    func test_fixed_year() throws {
        var boundary = DateBoundary(fixedYear: 2020)
        XCTAssertEqual(2020, boundary.year)
        
        // builder
        boundary =
            DateBoundaryBuilder()
            .fixedYear(2020)
            .build()
        XCTAssertEqual(2020, boundary.year)
    }
    
    func test_person_event() throws {
        var boundary = DateBoundary(event: .deces,
                                    name: "M. Lionel MICHAUD")
        XCTAssertEqual(2080, boundary.year)
        var year = DateBoundary.yearOf(lifeEvent: .deces,
                                       for: "M. Lionel MICHAUD")
        XCTAssertEqual(year, 2080)
        
        boundary = DateBoundary(event: .dependence,
                                name: "M. Lionel MICHAUD")
        XCTAssertEqual(2070, boundary.year)
        year = DateBoundary.yearOf(lifeEvent: .dependence,
                                   for: "M. Lionel MICHAUD")
        XCTAssertEqual(year, 2070)
        
        boundary = DateBoundary(event: .deces,
                                name: "M. Truc")
        XCTAssertNil(boundary.year)
        year = DateBoundary.yearOf(lifeEvent: LifeEvent.deces,
                                   for: "M. Truc")
        XCTAssertNil(year)
        
        // builder
        boundary =
            DateBoundaryBuilder()
            .on(event: .deces, of: "M. Lionel MICHAUD")
            .build()
        XCTAssertEqual(2080, boundary.year)
        year = DateBoundary.yearOf(lifeEvent: .deces,
                                   for: "M. Lionel MICHAUD")
        XCTAssertEqual(year, 2080)
        
    }
    
    func test_group_of_person_event() throws {
        var boundary = DateBoundary(event: LifeEvent.deces,
                                    group: GroupOfPersons.allAdults,
                                    order: SoonestLatest.soonest)
        XCTAssertEqual(2080, boundary.year)
        var year = DateBoundary.yearOf(lifeEvent : LifeEvent.deces,
                                       for       : GroupOfPersons.allAdults,
                                       order     : SoonestLatest.soonest)
        XCTAssertEqual(year, 2080)
        
        boundary = DateBoundary(event: LifeEvent.dependence,
                                group: GroupOfPersons.allAdults,
                                order: SoonestLatest.soonest)
        XCTAssertEqual(2070, boundary.year)
        year = DateBoundary.yearOf(lifeEvent : LifeEvent.dependence,
                                   for       : GroupOfPersons.allAdults,
                                   order     : SoonestLatest.soonest)
        XCTAssertEqual(year, 2070)
        
        boundary = DateBoundary(event: LifeEvent.deces,
                                group: GroupOfPersons.allChildrens,
                                order: SoonestLatest.latest)
        XCTAssertNil(boundary.year)
        year = DateBoundary.yearOf(lifeEvent : LifeEvent.deces,
                                   for       : GroupOfPersons.allChildrens,
                                   order     : SoonestLatest.latest)
        XCTAssertNil(year)
        
        // builder
        boundary =
            DateBoundaryBuilder()
            .on(event: .deces, of: .allAdults, taking: .soonest)
            .build()
        XCTAssertEqual(2080, boundary.year)
        year = DateBoundary.yearOf(lifeEvent : .deces,
                                   for       : .allAdults,
                                   order     : .soonest)
        XCTAssertEqual(year, 2080)
    }
}
