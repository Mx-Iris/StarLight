//
//  UserDefault.swift
//  LocalizationStudioUtilities
//
//  Created by JH on 2024/8/1.
//

import Foundation
import Combine
import Defaults

public typealias UserDefaultSerializable = Defaults.Serializable

private struct AnyDefaultSerializable<T: Codable>: Codable, Defaults.Serializable {
    let wrappedValue: T
}

@propertyWrapper
public struct UserDefault<T: UserDefaultSerializable> {
    public var wrappedValue: T {
        set {
            Defaults[key] = newValue
            _cache.value = Defaults[key]
        }
        get {
            if let value = _cache.value {
                return value
            } else {
                let wrappedValue = Defaults[key]
                _cache.value = wrappedValue
                return wrappedValue
            }
        }
    }

    private class Cache {
        var value: T?
    }
    
    private let _cache: Cache = .init()
    
    private let key: Defaults.Key<T>

    public init(key: String = #function, suite: UserDefaults = .standard, defaultValue: T) {
        self.key = Defaults.Key(key, default: defaultValue, suite: suite)
    }
    
    public var projectedValue: some Publisher<T, Never> {
        Defaults.publisher(key).map { $0.newValue }.eraseToAnyPublisher()
    }
}
