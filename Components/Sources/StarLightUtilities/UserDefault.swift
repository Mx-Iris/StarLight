import Foundation
import Combine
import Defaults
import FoundationToolbox

private struct AnyDefaultSerializable<T: Codable>: Codable, Defaults.Serializable {
    let wrappedValue: T
}

@propertyWrapper
public struct UserDefault<T: Codable> {
    public var wrappedValue: T {
        set {
            Defaults[key] = .init(wrappedValue: newValue)
            _cacheWrappedValue = Defaults[key]
        }
        mutating get {
            if let value = _cacheWrappedValue?.wrappedValue {
                return value
            } else {
                let wrappedValue = Defaults[key]
                _cacheWrappedValue = wrappedValue
                return wrappedValue.wrappedValue
            }
        }
    }

    @RecursiveLock
    private var _cacheWrappedValue: AnyDefaultSerializable<T>?

    private let key: Defaults.Key<AnyDefaultSerializable<T>>

    public init(key: String = #function, suite: UserDefaults = .standard, defaultValue: T) {
        self.key = Defaults.Key(key, default: .init(wrappedValue: defaultValue), suite: suite)
    }

    public var projectedValue: some Publisher<T, Never> {
        Defaults.publisher(key).map { $0.newValue.wrappedValue }.eraseToAnyPublisher()
    }
}
