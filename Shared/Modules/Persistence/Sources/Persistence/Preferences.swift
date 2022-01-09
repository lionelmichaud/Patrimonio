//
//  File.swift
//  
//
//  Created by Lionel MICHAUD on 08/01/2022.
//

import SwiftUI
import Combine
import Ownership

@propertyWrapper
public struct UserDefault<Value> {
    let key: String
    let defaultValue: Value
    
    public var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }
    
    init(wrappedValue: Value, _ key: String) {
        self.defaultValue = wrappedValue
        self.key = key
    }
    
    public static subscript(
        _enclosingInstance instance: Preferences,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Preferences, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Preferences, Self>
    ) -> Value {
        get {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            return container.object(forKey: key) as? Value ?? defaultValue
        }
        set {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            container.set(newValue, forKey: key)
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}

@propertyWrapper
public struct UserEnumDefault<Value: RawRepresentable> {
    let key: String
    let defaultValue: Value.RawValue
    
    public var wrappedValue: Value {
        get { fatalError("Wrapped value should not be used.") }
        set { fatalError("Wrapped value should not be used.") }
    }
    
    init(wrappedValue: Value, _ key: String) {
        self.defaultValue = wrappedValue.rawValue
        self.key = key
    }
    
    public static subscript(
        _enclosingInstance instance: Preferences,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<Preferences, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<Preferences, Self>
    ) -> Value {
        get {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            let defaultValue = instance[keyPath: storageKeyPath].defaultValue
            let rawValue = container.object(forKey: key) as? Value.RawValue ?? defaultValue
            return Value(rawValue: rawValue)!
        }
        set {
            let container = instance.userDefaults
            let key = instance[keyPath: storageKeyPath].key
            container.set(newValue.rawValue, forKey: key)
            instance.preferencesChangedSubject.send(wrappedKeyPath)
        }
    }
}

/// This wrapper can be useful whenever you want to have a publisher as input for triggering a SwiftUI change.
/// In this case, we’re using the passthrough subject from our preferences container as an input to trigger changes
/// in our dynamic @Preference property wrapper.
final class PublisherObservableObject: ObservableObject {
    
    var subscriber: AnyCancellable?
    
    init(publisher: AnyPublisher<Void, Never>) {
        subscriber = publisher.sink(receiveValue: { [weak self] _ in
            self?.objectWillChange.send()
        })
    }
}

/// Préferences utilisateur
///
/// Usage:
///    ```
///      @Preference(\.shouldShowHelloWorld) var shouldShowHelloWorld
///    ```
@propertyWrapper
public struct Preference<Value>: DynamicProperty {
    
    @ObservedObject private var preferencesObserver: PublisherObservableObject
    private let keyPath: ReferenceWritableKeyPath<Preferences, Value>
    private let preferences: Preferences
    
    public init(_ keyPath: ReferenceWritableKeyPath<Preferences, Value>, preferences: Preferences = .standard) {
        self.keyPath = keyPath
        self.preferences = preferences
        let publisher = preferences
            .preferencesChangedSubject
            .filter { changedKeyPath in
                changedKeyPath == keyPath
            }.map { _ in () }
            .eraseToAnyPublisher()
        self.preferencesObserver = .init(publisher: publisher)
    }
    
    public var wrappedValue: Value {
        get { preferences[keyPath: keyPath] }
        nonmutating set { preferences[keyPath: keyPath] = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { wrappedValue = $0 }
        )
    }
}

// MARK: - Preferences Utilisateur

///
/// Usage:
///    ```
///    @UserDefault("should_Show_Hello_World")
///    public var shouldShowHelloWorld: Bool = true
///
///    // Inside a SwiftUI View
///    struct ContentView: View {
///
///      @Preference(\.shouldShowHelloWorld) var shouldShowHelloWorld
///
///      var body: some View {
///          VStack {
///              Text(shouldShowHelloWorld ? "Hello, world!" : "")
///                  .padding()
///              Button("Change text") {
///                  shouldShowHelloWorld.toggle()
///              }
///              Toggle("Change text", isOn: $shouldShowHelloWorld)
///          }
///      }
///    }
///
///    // We can also access the passthrough subject directly
///    // on the preferences container to observe specific changes
///    // from within other instances:
///    let subscription = Preferences.standard
///      .preferencesChangedSubject
///          .filter { changedKeyPath in
///              changedKeyPath == \Preferences.shouldShowHelloWorld
///          }.sink { _ in
///              print("Should show hello world preference changed!")
///          }
///    ```
public final class Preferences {
    
    public static let standard = Preferences(userDefaults: .standard)
    fileprivate let userDefaults: UserDefaults
    
    /// Sends through the changed key path whenever a change occurs.
    public var preferencesChangedSubject = PassthroughSubject<AnyKeyPath, Never>()
    
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    /// Paramètres de simulation
    @UserDefault("simulate_volatility")
    public var simulateVolatility: Bool = false
    
    /// Paramètres de gestion de fichiers
    @UserDefault("share_CSV_files")
    public var shareCsvFiles: Bool = true
    
    @UserDefault("share_image_files")
    public var shareImageFiles: Bool = true

    /// Paramètres Graphiques
    // graphique Bilan
    @UserEnumDefault("ownership_graphic_selection")
    public var ownershipGraphicSelection: OwnershipNature = OwnershipNature.sellable
//    public var ownershipGraphicSelection: OwnershipNature {
//        get {
//            OwnershipNature(rawValue: ownershipGraphicSelectionString) ?? OwnershipNature.sellable
//        }
//        set {
//            ownershipGraphicSelectionString = newValue.rawValue
//        }
//    }
    @UserEnumDefault("asset_graphic_evaluated_fraction")
    public var assetGraphicEvaluatedFraction: EvaluatedFraction = EvaluatedFraction.ownedValue
//    public var assetGraphicEvaluatedFraction: EvaluatedFraction {
//        get {
//            EvaluatedFraction(rawValue: assetGraphicEvaluatedFractionString) ?? EvaluatedFraction.ownedValue
//        }
//        set {
//            assetGraphicEvaluatedFractionString = newValue.rawValue
//        }
//    }
}
