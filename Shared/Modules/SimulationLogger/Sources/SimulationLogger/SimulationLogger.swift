//
//  Logger.swift
//  Patrimoine
//
//  Created by Lionel MICHAUD on 30/03/2021.
//  Copyright © 2021 Lionel MICHAUD. All rights reserved.
//

import Foundation
import AppFoundation

public enum LogTopic: String, PickableEnumP, Codable {
    case simulationEvent = "Simulation"
    case lifeEvent       = "Evénement de vie"
    case error           = "Erreur"
    case other           = "Autre"
    
    // MARK: - Computed Properties
    
    public var pickerString: String {
        return self.rawValue
    }
    
    public var description: String {
        pickerString
    }
}

/// The Singleton class defines the `shared` field that lets clients access the
/// unique singleton instance.
public final class SimulationLogger: CustomStringConvertible {
     
    // MARK: - Type Properties
    /// The static field that controls the access to the singleton instance.
    ///
    /// This implementation let you extend the Singleton class while keeping
    /// just one instance of each subclass around.
    public static var shared: SimulationLogger = {
        let instance = SimulationLogger()
        // ... configure the instance
        // ...
        return instance
    }()
    
    // MARK: - Properties
    
    private var activ    = true
    private(set) var log = [String]()
    public var description: String {
        log.reduce("") { r, item in
            r + String(describing: item) + "\n"
        }
    }

    // MARK: - Initializers
    
    /// The Singleton's initializer should always be private to prevent direct
    /// construction calls with the `new` operator.
    private init() {}
    
    // MARK: - Methods
    
    /// Finally, any singleton should define some business logic, which can be
    /// executed on its instance.
    public func start() {
        activ = true
    }
    
    public func stop() {
        activ = false
    }
    
    public func reset() {
        log = [ ]
    }
    
    public func dumpAll() {
        log.forEach {
            print($0)
        }
    }
    
    public func dump(run: Int) {
        log.filter {
            $0.starts(with: "Run: \(run)")
        }
        .forEach {
            print($0)
        }
    }
    
    public func log(run      : Int = 0,
                    logTopic : LogTopic,
                    message  : String) {
        guard activ else { return }
        
        let output = "Run: \(run) | \(logTopic.description) | \(message)"
        
        // historiser
        log.append(output)
        
        // sortie console
        print(output)
    }
}

/// Singletons should not be cloneable.
extension SimulationLogger: NSCopying {
    
    public func copy(with zone: NSZone? = nil) -> Any {
        return self
    }
}
