import Foundation

/// Usage:
///
///   ```
///   // protocol de l'objet à injecter
///   protocol NetworkProviding {
///       func requestData()
///   }
///
///   // clé d'injection
///   private struct NetworkProviderKey: InjectionKeyP {
///       static var currentValue: NetworkProviding = NetworkProvider()
///   }
///    ```
public protocol InjectionKeyP {

    /// The associated type representing the type of the dependency injection key's value.
    associatedtype Value

    /// The default value for the dependency injection key.
    static var currentValue: Self.Value { get set }
}

/// Provides access to injected dependencies.
///
/// Usage:
///   ```
///   // doit être étendue avec une propriété pour chaque objet injecté
///   extension InjectedValues {
///       var networkProvider: NetworkProviding {
///           get { Self[NetworkProviderKey.self] }
///           set { Self[NetworkProviderKey.self] = newValue }
///       }
///   }
///   ```
struct InjectedValues {

    /// This is only used as an accessor to the computed properties within extensions of `InjectedValues`.
    private static var current = InjectedValues()

    /// A static subscript for updating the `currentValue` of `InjectionKey` instances.
    static subscript<K>(key: K.Type) -> K.Value where K : InjectionKeyP {
        get { key.currentValue }
        set { key.currentValue = newValue }
    }

    /// A static subscript accessor for updating and references dependencies directly.
    static subscript<T>(_ keyPath: WritableKeyPath<InjectedValues, T>) -> T {
        get { current[keyPath: keyPath] }
        set { current[keyPath: keyPath] = newValue }
    }
}

/// Property Wrapper
///
/// Usage:
///
///   ```
///   // protocol de l'objet à injecter
///   protocol NetworkProviding {
///       func requestData()
///   }
///
///   // clé d'injection
///   private struct NetworkProviderKey: InjectionKeyP {
///       static var currentValue: NetworkProviding = NetworkProvider()
///   }
///
///   // doit être étendue avec une propriété pour chaque objet injecté
///   extension InjectedValues {
///       var networkProvider: NetworkProviding {
///           get { Self[NetworkProviderKey.self] }
///           set { Self[NetworkProviderKey.self] = newValue }
///       }
///   }
///
///   // l'objet dans lequel on injecte les dépendances
///   struct DataController {
///       @Injected(\.networkProvider) var networkProvider: NetworkProviding
///
///       func performDataRequest() {
///           networkProvider.requestData()
///       }
///   }
///   ```
@propertyWrapper
struct Injected<T> {
    private let keyPath: WritableKeyPath<InjectedValues, T>
    var wrappedValue: T {
        get { InjectedValues[keyPath] }
        set { InjectedValues[keyPath] = newValue }
    }

    init(_ keyPath: WritableKeyPath<InjectedValues, T>) {
        self.keyPath = keyPath
    }
}
