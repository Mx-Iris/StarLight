import Foundation
import Combine
import KeychainAccess
import FoundationToolbox

@propertyWrapper
public struct Keychain<T: Codable> {
    private let keychain: KeychainAccess.Keychain

    private let subject = PassthroughSubject<T, Never>()

    public var wrappedValue: T {
        set {
            do {
                keychain[data: key] = try JSONEncoder().encode(newValue)
                _cacheWrappedValue = newValue
                subject.send(newValue)
            } catch {
                print(error)
            }
        }
        mutating get {
            if let _cacheWrappedValue {
                return _cacheWrappedValue
            } else {
                if let data = keychain[data: key],
                   let value = try? JSONDecoder().decode(T.self, from: data) {
                    _cacheWrappedValue = value
                    return value
                } else {
                    return defaultValue
                }
            }
        }
    }

    @RecursiveLock
    private var _cacheWrappedValue: T?

    private let defaultValue: T

    private let key: String

    public init(key: String, service: String, defaultValue: T) {
        self.keychain = .init(service: service).synchronizable(true)
        self.key = key
        self.defaultValue = defaultValue
    }

    public var projectedValue: some Publisher<T, Never> {
        subject.eraseToAnyPublisher()
    }
}
